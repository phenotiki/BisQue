function Phidias(mex_url, access_token, resource_url, varargin)
    if ~isdeployed
        addpath('phenotype_descriptors');
    end
    try
        session = bq.Session(mex_url, access_token);

        session.update('Initializing..'); 

        % Load images from Bisque server
        image = session.fetch(resource_url);

        if isempty(image),
            fprintf('Failed to fetch image: %s\n', resource_url);
            return;
        end

        %% Start of Segmentation Algorithm
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


        % Execute Pipeline
        for i = 1 : number_t
            fprintf(['***** Image: ', int2str(i), ' *****']);    
            session.update('Analysing..');   
            I = image.slice([],i).fetch(); 

            [plant_centroids, cluster_center, Gmm, previous, labelled_mask_fullres_ls] = pipeline(I, session, plant_centroids, cluster_center, isFirst, display, Gmm, previous, lambda, small_size, enable_appearance_model);

            labelled_mask{i} = labelled_mask_fullres_ls;
            isFirst = false;              
        end

        session.update('Analysing - 100%'); 

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
            temp_mask = labelled_mask{m};
            areas(:,m) = analysis_pla(temp_mask);
            diameters(:,m) = analysis_diameter(temp_mask);
            perimeters(:,m) = analysis_perimeter(temp_mask);
            stocks(:,m) = analysis_stockiness(temp_mask);
            compacts(:,m) = analysis_compactness(temp_mask);
        end    

        time_plants = cell(1, number_t);
        mask_plants = cell(plant_num, 1);

        % for each mask in the time-series
        for t = 1 : number_t
            temp_mask = labelled_mask{t};
            % for each plant in the mask
            for p = 1 : plant_num
                [x, y] = find(temp_mask == p);
                temp_plant = [x,y];
                mask_plants{p,1} = temp_plant;
            end
            time_plants{1, t} = mask_plants;
        end

        %% Create Output Session
        outputs = session.mex.addTag('outputs');  
        imref = outputs.addTag('Segmented Image', resource_url, 'image');
        s = imref.addGobject('Object', 'Segmented Object');
        pl = imref.addGobject('Object', 'Plot');

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
        time = TimeStamp;
        summary.addTag(sprintf('Timestamp'), time);    

        myRGBcolors = hsv(plant_num);

        for i = 1 : number_t
            cnt = time_plants{i};
            for l = 1 : plant_num
                boundaries = cnt{l,1};
                dim = size(boundaries, 1);
                T = ones(dim, 1) * i;
                z = ones(dim, 1);
                vertices = [boundaries, z, T];
                polyg = s.addGobject('polygon', sprintf('Boundary Plant %d', l), vertices);
                hex = rgb2hex(myRGBcolors(l,:));
                polyg.addTag('color', hex , 'color');
            end
        end         

        for p = 1 : plant_num
            plantName = ['Plant-', num2str(p)];
            tl = pl.addGobject('Plants', plantName);
            for q = 1 : number_t         
                tempA = areas(p, q);
                tempD = diameters(p,q);
                tempP = perimeters(p,q);
                tempS = stocks(p,q);
                tempC = compacts(p,q);
                tl.addTag('area', tempA, 'number');
                tl.addTag('diameter', tempD, 'number');
                tl.addTag('perimeter', tempP, 'number');
                tl.addTag('stockiness', tempS, 'number');
                tl.addTag('compactness', tempC, 'number');
            end
        end    

        session.update('Saving results..');

        session.finish();
    catch err
       ErrorMsg = [err.message, 10, 'Stack:', 10];
       for i=1:size(err.stack,1)
           ErrorMsg = [ErrorMsg, '     ', err.stack(i,1).file, ':', num2str(err.stack(i,1).line), ':', err.stack(i,1).name, 10];
       end
       session.fail(ErrorMsg);
    end     
end
