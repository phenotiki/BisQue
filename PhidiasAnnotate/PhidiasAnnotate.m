function PhidiasAnnotate(mex_url, access_token, image_url)

    session = bq.Session(mex_url, access_token);
    
    session.update('Fetching image..');
    
    image = session.fetch(image_url);
    I = image.fetch();
    image.addTag('Type', 'image');
    image.save();
    
%     Parse the polygones vertices.
    polygones = session.mex.findNodes('//tag[@name="inputs"]/tag[@name="resource_url"]/gobject[@name="stroke"]/polygon');
    
    coord = zeros(length(polygones), 2);
    
    session.update('Finding polygones..');
    
    N = size(polygones, 1);
    
    vertices = cell(N, 1);
    
    for i = 1 : N
        v = polygones{i}.getVertices();
        x = v(:, 2);
        y = v(:, 1);
        vertices{i} = [round(x) round(y)];
    end
    
    mask = zeros(size(I,1), size(I,2));
    
    for j = 1 : N
        coord = vertices{j};

        % ensure that the polygon is closed
        if ~isequal(coord(1,:), coord(end,:))
        % append first vertex at the end of the list
            coord(end+1,:) = coord(1,:);
        end

        % swap the coordinates, i.e. y,x --> x,y
        coord(:,[1,2]) = coord(:,[2,1]);

        % find perimeter
        for j = 1:size(coord, 1)
            P = bqBresenham(coord);
        end
        
        % map perimeter on the 2D plane
        for k = 1:size(P, 1)
            mask(P(k,1), P(k,2)) = 255;
        end
        
        % fill the polygon
        mask = imfill(mask, 'holes');
        
    end  

%     imwrite(mask, 'foglia_M.png')
%     figure, imshow(mask)

    M = uint8(mask);
    
    file = image.info.filename;
    [~, imageName, ~] = fileparts(file);
    
    %host = 'http://fabiana-macbookpro:8080';
    %user = 'Mex';
    %pass = access_token;
    
    t = TimeStamp;
    
    maskName = [imageName, '_mask',t ,'.tiff'];
    args = struct('filename', maskName);
    %imMask = bq.Image.store(M, args, host, user, pass);
    imMask = session.storeImage(M, args);
    if ~isempty(imMask),
        imMask.addTag('About', 'Segmentation mask created with PhidiasAnnotate');
        imMask.addTag('Original Image', file);
        imMask.addTag('Type', 'mask');
        imMask.save();
    end
       
    mask_url = imMask.getAttribute('uri');
    
    outputs = session.mex.addTag('outputs');
    maskref = outputs.addTag('Segmented Mask', mask_url, 'image');
    summary = outputs.addTag('summary');
    
    summary.addTag(sprintf('Filename'), maskName);
    summary.addTag(sprintf('Original Image'), file);

    session.update('Saving mask..');

    session.finish();
end
