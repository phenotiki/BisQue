function PhidiasModel(mex_url, access_token, resource_url, varargin)

    session = bq.Session(mex_url, access_token);

    session.update('Initializing..');
    
    %% Input Parameters
    
    % Grid Search
    lambda_lower = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda_lower"]');
    lambda_upper = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda_upper"]');
    lambda_step = session.mex.findValue('//tag[@name="inputs"]/tag[@name="lambda_step"]');
    
    small_size_lower = session.mex.findValue('//tag[@name="inputs"]/tag[@name="small_size_lower"]');
    small_size_upper = session.mex.findValue('//tag[@name="inputs"]/tag[@name="small_size_upper"]');
    small_size_step = session.mex.findValue('//tag[@name="inputs"]/tag[@name="small_size_step"]');
    
    
    % Others
    plant_num = session.mex.findValue('//tag[@name="inputs"]/tag[@name="num_plants"]');
    gauss = session.mex.findValue('//tag[@name="inputs"]/tag[@name="gauss"]');

    %% Initialization 
    
    url = [resource_url '?view=deep'];
    user = 'Mex';	
    pass = access_token;
    dataset = bq.Factory.fetch(url, [], user, pass);
    objects = dataset.getValues('object');
    
    dim = size(objects, 2);
    
    session.update('Checking dataset..');
    
    if (rem(dim,2) ~= 0)
        fprintf('Your dataset contains an odd number of images. Please be sure that it includes a mask for each image.\n');
        outputs = session.mex.addTag('outputs');  
        errors = outputs.addTag('errors');
        errors.addTag(sprintf('Your dataset contains an odd number of images. Please be sure that it includes a mask for each image,'));
        session.update('Terminating..');
        session.finish();
        return;
    else
    
        % images in the dataset: image matrix in the first dimension, filename in the second dimension
        I = cell(dim/2, 2);
        % masks in the dataset: image matrix in the first dimension, filename in the second dimension
        M = cell(dim/2, 2);
        
        im_filenames = cell(dim/2, 1);
        matching = cell(dim/2, 2);

        mCount = 0; % masks count
        iCount = 0; % images count
        
        % Distinguish images and mask within the dataset verifying tags
        % correctness

        for i = 1 : dim
            im = bq.Factory.fetch([objects{i} '?view=deep'], [], user, pass);
            name = im.getAttribute('name');
            type = im.findValue('//tag[@name="Type"]');
            fprintf('image %d = %s, type = %s \n',i, name, type);            
            if (~isempty(type))
                if (strcmp(type, 'mask'))
                    orig = im.findValue('//tag[@name="Original Image"]');
                    mCount = mCount + 1;
                    M{mCount, 1} = im;
                    M{mCount, 2} = orig;
                    matching{mCount, 1} = name;
                    matching{mCount, 2} = orig;
                else if (strcmp(type, 'image'))
                    iCount = iCount + 1;
                    I{iCount, 1} = im;
                    I{iCount, 2} = name;
                    im_filenames{iCount, 1} = name;
                    else
                    fprintf(['Tag type for ',name ,' is wrong.\n']);
                    outputs = session.mex.addTag('outputs');  
                    errors = outputs.addTag('errors');
                    errors.addTag(sprintf(['Tag "Type" for ',name ,' is wrong.']));
                    session.update('Terminating..');
                    session.finish();
                    return;
                    end
                end
            else
                fprintf(['Tag "Type" not existing for ', name,'\n']);
                outputs = session.mex.addTag('outputs');  
                errors = outputs.addTag('errors');
                errors.addTag(sprintf(['Tag not existing for ', name]));
                session.update('Terminating..');
                session.finish();
                return;
            end
        end
    end
    
    % Verify that each image has its own mask
    
    ImF = sort(im_filenames);
    Mat = sort(matching(:,2));
    
    if (~isequal(ImF, Mat))
        fprintf('Masks do not correpond to images. Please check your dataset.\n');
        outputs = session.mex.addTag('outputs');  
        errors = outputs.addTag('errors');
        errors.addTag(sprintf('Masks do not correpond to images. Please check your dataset.'));
        session.update('Terminating..');
        session.finish();
        return;
    end
    
    
    %% Data Preparation for Grid Search
    
    session.update('Preparing Data for Grid Search..');
    
    % Create the arrays for Input Parameters
    small_size = small_size_lower:small_size_step:small_size_upper;
    lambda = lambda_lower:lambda_step:lambda_upper;
    appearance = [true, false];

    % Create the grid with all parameter combinations
    grid = allcomb(small_size, lambda, appearance);
    
    grid(find(grid(:,3) == 1), 2) = 0.5;
    grid = unique(grid, 'rows');
    
    S = size(grid,1);
    
    D = zeros(S, 1);
    
    % Retrieve masks from dataset
        
    masks_n = size(M, 1);
    GTM = cell(masks_n, 2);

    for l = 1 : masks_n
        node = M{l, 1};
        gt_mask = node.slice(1,1).fetch();
        GTM{l, 1} = gt_mask;    
        GTM{l, 2} = M{l, 2}; 
    end
    
    % Retrieve images from dataset and create Train GMM
    
    img_n =  size(I,1);
    Imm = cell(img_n, 2);
    features = [];

    for m = 1 : img_n
        node = I{m, 1};
        img = node.slice(1,1).fetch();
        Imm{m, 1} = img;
        Imm{m, 2} = I{m, 2};
        nrows = size(Imm{m, 1}, 1);
        ncols= size(Imm{m, 1}, 2);
        F = extract_features(Imm{m, 1}, session);
        X = reshape(F, nrows*ncols, size(F,3));
        [~, row_id] = ismember(Imm{m, 2}, GTM(:,2));
        mask_fg = logical(GTM{row_id, 1});
        X_new = X(mask_fg(:), :);
        features = [features; X_new];
    end
    
    Gmm = gmdistribution.fit(features, gauss);
    

%% Grid Search

    for k = 1 : S
        fprintf('\n--------- Grid Search Iteration: (%d) ---------\n', k);
        
        session.update(['Executing Grid Search (Step ', int2str(k), '/', int2str(S),')..']);
        
        small_size = grid(k,1);
        lambda = grid(k,2);
        enable_appearance_model = grid(k,3);

        fprintf('small_size = %d\nlambda = %.2f\nenable_appearance_model = %d\n', grid(k,:));

        display = false;
        
        % Call the pipeline for each image in the dataset
        
        im_size = size(Imm, 1);
        GSM = cell(im_size, 2);
        
        for j = 1 : im_size
            image = Imm{j, 1};
            img_name = Imm{j, 2};
            fprintf('\n--------- Image: (%d) ---------\n', j);
            tStart = tic;
            try
                mask_final = pipeline(image, plant_num, display, session, Gmm, small_size, lambda, enable_appearance_model);
            catch exception
                fprintf('\n******** Pipeline Execution Failed!!! ********\n');
                err = getReport(exception);
                fprintf(err);
                continue
            end
            tElapsed = toc(tStart);
            fprintf('\nTotal elapsed time (s): %.3f\n', tElapsed);
            
            GSM{j,1} = mask_final;
            GSM{j,2} = img_name;
            
        end
        
        try
        D(k) = grid_search_dsc(GTM, GSM, session);
        catch exc
            fprintf('\n******** Grid Search Failed!!! ********\n');
            er = getReport(exc);
            fprintf(er);
            continue
        end
    end
    
    %% Create Output Session
    
    session.update('Saving results..');

    [d_max, k_max] = max(D);
    
    t = TimeStamp();
    
    filename = ['PhidiasModel', t, '.mat'];
    
    gs_small_size = grid(k_max, 1);
    gs_lambda = grid(k_max, 2);
    gs_eam = grid(k_max, 3);
    
    save(filename, 'Gmm', 'gs_small_size', 'gs_lambda', 'gs_eam');
    
    %%host = 'http://fabiana-macbookpro:8080';
    %%user = 'Mex';
    %%pass = access_token;
    
    %%file = bq.File.store(filename, host, user, pass);
       mex_id = strsplit(mex_url, '/'); mex_id = mex_id{end};
       dt = datestr(now,'yyyymmddTHHMMss');

    resource = bq.Factory.new ('file', ['ModuleExections/Phidias/' mex_id  '/' dt '.mat' ] );
    resource.setAttribute('permission', 'published');
    resource.addTag('about', 'File upload from PhidiasModel');
    file = session.storeFile (filename, resource);

    %if ~isempty(file),
    %    file.
    %    file.addTag('about', 'File upload from PhidiasModel');
    %    file.save();
    %end
    
    file_url = file.getAttribute('uri');
    
    delete(filename);
    
    outputs = session.mex.addTag('outputs');  
    results = outputs.addTag('results');
    results.addTag(sprintf('iteration'), k_max);
    results.addTag(sprintf('DSC'), d_max);
    results.addTag(sprintf('small_size'), gs_small_size);
    results.addTag(sprintf('lambda'), gs_lambda);
    results.addTag(sprintf('enable_appearance_model'), gs_eam);
    results.addTag(sprintf('.mat file url'), file_url);

    session.finish();
    
end
