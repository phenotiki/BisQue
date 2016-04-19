function PhidiasAnnotate(mex_url, access_token, image_url)
%PHIDIASANNOTATE Module for BisQue.
%
%   Author(s): Massimo Minervini, Fabiana Zollo
%   Contact:   massimo.minervini@imtlucca.it
%   Version:   1.0
%   Date:      --
%
%   Copyright (C) 2016 Massimo Minervini
%
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
%   BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
%   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    try
        session = bq.Session(mex_url, access_token);

        session.update('Fetching image...');

        image = session.fetch(image_url);
        I = image.fetch();
        image.addTag('Type', 'image');
        image.save();

    %     Parse the polygones vertices.
        polygones = session.mex.findNodes('//tag[@name="inputs"]/tag[@name="resource_url"]/gobject[@name="stroke"]/polygon');

        coord = zeros(length(polygones), 2);

        session.update('Finding polygons...');

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

        mex_name = session.mex.getAttribute('name');
        mex_id = strsplit(mex_url, '/'); mex_id = mex_id{end};
        dt = datestr(now,'yyyymmddTHHMMss');    
        path = sprintf('ModuleExecutions/%s/%s_%s/', mex_name, dt, mex_id);

        maskName = [imageName, '_mask',t ,'.tiff'];
        args = struct('filename', maskName);
        %imMask = bq.Image.store(M, args, host, user, pass);
        resource = bq.Factory.new ('image', [path maskName]);
        resource.addTag('About', 'Segmentation mask created with PhidiasAnnotate');
        resource.addTag('Original Image', file);
        resource.addTag('Type', 'mask');

        session.update('Saving image mask...');
        imMask = session.storeImage(M, args, resource);
        %if ~isempty(imMask),
        %    imMask.addTag('About', 'Segmentation mask created with PhidiasAnnotate');
        %    imMask.addTag('Original Image', file);
        %    imMask.addTag('Type', 'mask');
        %    imMask.save();
        %end

        mask_url = imMask.getAttribute('uri');

        outputs = session.mex.addTag('outputs');
        maskref = outputs.addTag('Segmented Mask', mask_url, 'image');
        summary = outputs.addTag('summary');

        summary.addTag(sprintf('Filename'), maskName);
        summary.addTag(sprintf('Original Image'), file);

        session.update('Saving mask...');

        session.finish();
    catch err
       ErrorMsg = [err.message, 10, 'Stack:', 10];
       for i=1:size(err.stack,1)
           ErrorMsg = [ErrorMsg, '     ', err.stack(i,1).file, ':', num2str(err.stack(i,1).line), ':', err.stack(i,1).name, 10];
       end
       session.fail(ErrorMsg);
    end        
end
