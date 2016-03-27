function Phidias(mex_url, access_token, varargin)
if ~isdeployed
    addpath('phenotype_descriptors');
end
try
    session = bq.Session(mex_url, access_token);
    session.update('Initializing...');
    
    % Load images from Bisque server
    resource_url = session.mex.findValue('//tag[@name="inputs"]/tag[@name="resource_url"]');
    image = session.fetch(resource_url);
    if isempty(image)
        session.fail(sprintf('Failed to fetch input image(s): %s',resource_url));
        return
    end
    
    %% Plant segmentation algorithm
    display = false;
    plant_centroids = [];
    cluster_center = [];
    isFirst = true;
    number_t = max(1, image.info.image_num_t);
    previous = [];
    
    Gmm = [];
    lambda = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda"]');
    small_size = session.mex.findValue('//tag[@name="inputs"]/tag[@name="small_size"]');
    enable_appearance_model = str2bool(session.mex.findValue('//tag[@name="inputs"]/tag[@name="eam"]'));
    
    % Load .mat file (PhidiasModel Output)
    
    gs_output = session.mex.findValue('//tag[@name="inputs"]/tag[@name="gs_ouput"]');
    
    if ~isempty(gs_output)
        user = '';
        pass = '';
        
        file = bq.Factory.fetch(gs_output, [], user, pass);
        matFile = file.fetch( [] );
        
        load(matFile);
        
        lambda = gs_lambda;
        small_size = gs_small_size;
        enable_appearance_model = gs_eam;
        
        delete(matFile);
    end
    
    session.update('Plant segmentation in progress...');
    for i = 1:number_t
        fprintf(['***** Image: ', int2str(i), ' *****']);
        I = image.slice([],i).fetch();
        
        [plant_centroids, cluster_center, Gmm, previous, labelled_mask_fullres_ls] = pipeline(I, session, plant_centroids, cluster_center, isFirst, display, Gmm, previous, lambda, small_size, enable_appearance_model);
        
        labelled_mask{i} = labelled_mask_fullres_ls;
        isFirst = false;
    end
    session.update('Plant segmentation done!');
    
    %% Create Output Parameters
    
    plant_num = session.mex.findValue('//tag[@name="inputs"]/tag[@name="num_plants"]');
    crop_x1 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_x1"]');
    crop_x2 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_x2"]');
    crop_y1 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_y1"]');
    crop_y2 = session.mex.findValue('//tag[@name="inputs"]/tag[@name="crop_y2"]');
    gauss = session.mex.findValue('//tag[@name="inputs"]/tag[@name="gauss"]');
    scale_factor = session.mex.findValue('//tag[@name="inputs"]/tag[@name="scale_factor"]');
    iter = session.mex.findValue('//tag[@name="inputs"]/tag[@name="iter"]');
    noMedian = session.mex.findValue('//tag[@name="inputs"]/tag[@name="noMedian"]');
    sigma = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigma"]');
    sigma_P = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigma_P"]');
    sigmaH = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigmaH"]');
    sigmaL = session.mex.findValue('//tag[@name="inputs"]/tag[@name="sigmaL"]');
    radius = session.mex.findValue('//tag[@name="inputs"]/tag[@name="radius"]');
    falloff = session.mex.findValue('//tag[@name="inputs"]/tag[@name="falloff"]');
    lambda = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda"]');
    lambda_out = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda_out"]');
    gmm = str2bool(session.mex.findValue('//tag[@name="inputs"]/tag[@name="gmm"]'));
    
    areas = zeros(plant_num, number_t);
    diameters = zeros(plant_num, number_t);
    perimeters = zeros(plant_num, number_t);
    stocks = zeros(plant_num, number_t);
    compacts = zeros(plant_num, number_t);
    for m = 1:size(labelled_mask, 2)
        areas(:,m) = analysis_pla(labelled_mask{m});
        diameters(:,m) = analysis_diameter(labelled_mask{m});
        perimeters(:,m) = analysis_perimeter(labelled_mask{m});
        stocks(:,m) = analysis_stockiness(labelled_mask{m});
        compacts(:,m) = analysis_compactness(labelled_mask{m});
    end
    
    %% Create Output Session
    outputs = session.mex.addTag('outputs');
    imref = outputs.addTag('Segmented Image', resource_url, 'image');
    
    session.update('Saving segmentation masks...');
    s = imref.addGobject('Object', 'Segmentation mask');
    maxNumVertices = 200; % max number of vertices used to represent a plant contour
    rgbColorPalette = hsv(plant_num);
    for t = 1:number_t
        for p = 1:plant_num
            temp_bw_mask = false(size(labelled_mask{t}));
            temp_bw_mask(labelled_mask{t} == p) = true;
            cs = bwboundaries(temp_bw_mask, 'noholes');
            for c = 1:length(cs)
                if size(cs{c},1) > maxNumVertices
                    %fprintf('%d-%d-%d) reduce_poly: %d --> %d\n',t,p,c,size(cs{c},1),maxNumVertices)
                    cs{c} = reduce_poly(cs{c}', maxNumVertices)';
                end
                polyg = s.addGobject('polygon', sprintf('Plant %d, contour %d',p,c), [cs{c} repmat([1 t], size(cs{c},1), 1)]);
                polyg.addTag('color', rgb2hex(rgbColorPalette(p,:)), 'color');
            end
        end
    end
    
    session.update('Saving analysis results...');
    pl = imref.addGobject('Object', 'Plot');
    for p = 1:plant_num
        plantName = ['Plant-', num2str(p)];
        tl = pl.addGobject('Plants', plantName);
        for t = 1:number_t
            tl.addTag('area', areas(p,t), 'number');
            tl.addTag('diameter', diameters(p,t), 'number');
            tl.addTag('perimeter', perimeters(p,t), 'number');
            tl.addTag('stockiness', stocks(p,t), 'number');
            tl.addTag('compactness', compacts(p,t), 'number');
        end
    end
    
    summary = outputs.addTag('summary');
    summary.addTag(sprintf('Number of plants'), plant_num);
    summary.addTag(sprintf('Left crop'), crop_x1);
    summary.addTag(sprintf('Right crop'), crop_x2);
    summary.addTag(sprintf('Top crop'), crop_y1);
    summary.addTag(sprintf('Bottom crop'), crop_y2);
    summary.addTag(sprintf('Scale factor'), scale_factor);
    summary.addTag(sprintf('Small object size'), small_size);
    summary.addTag(sprintf('Texture DoG sigma H'), sigmaH);
    summary.addTag(sprintf('Texture DoG sigma L'), sigmaL);
    summary.addTag(sprintf('Texture radius'), radius);
    summary.addTag(sprintf('Texture alpha'), falloff);
    summary.addTag(sprintf('Enable GMM'), enable_appearance_model);
    summary.addTag(sprintf('GMM component'), gauss);
    summary.addTag(sprintf('GMM Update'), gmm);
    summary.addTag(sprintf('GMM prior sigma'), sigma_P);
    summary.addTag(sprintf('ACM max iterations'), iter);
    summary.addTag(sprintf('ACM no median'), noMedian);
    summary.addTag(sprintf('ACM sigma'), sigma);
    summary.addTag(sprintf('ACM lambda'), lambda);
    summary.addTag(sprintf('ACM lambda bg'), lambda_out);
    summary.addTag(sprintf('PhidiasModel Output: File URL'), gs_output);
    summary.addTag(sprintf('Timestamp'), TimeStamp);
    
    session.finish();
catch err
    ErrorMsg = [err.message, 10, 'Stack:', 10];
    for i=1:size(err.stack,1)
        ErrorMsg = [ErrorMsg, '     ', err.stack(i,1).file, ':', num2str(err.stack(i,1).line), ':', err.stack(i,1).name, 10];
    end
    disp(ErrorMsg)
    session.fail(ErrorMsg);
end
end
