function mask = levelset(I, F, Iter, Sigma, u, display, noMedian, lambda, lambda_out,  P)
%LEVELSET Level-set based active contour segmentation.
%
%   Author(s): Massimo Minervini
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

% Load system options
%config;

% Gaussian kernel
KernelSize = 2 * round(2 * Sigma) + 1;
G = fspecial('gaussian', KernelSize, Sigma);

% Features
[nrows, ncols, feature_n] = size(F);

% Normalize image features to range [0,100]
for i = 1:feature_n
    F(:,:,i) = normalize(F(:,:,i)) * 100;
end

ImgA = double(F(:,:,1));
ImgB = double(F(:,:,2));
ImgT = double(F(:,:,3));

% Probability map
if exist('P', 'var') % Multiply each component by the probability map
    
    ImgAo = lambda_out*ImgA.*(1-P);
    ImgAi = ImgA.*P;
    
    ImgBo = lambda_out*ImgB.*(1-P);
    ImgBi = ImgB.*P;
    
    ImgTo = lambda_out*ImgT.*(1-P);
    ImgTi = ImgT.*P;
else % No probability map is provided
    ImgAo = ImgA;
    ImgAi = ImgA;
    
    ImgBo = ImgB;
    ImgBi = ImgB;
    
    ImgTo = ImgT;
    ImgTi = ImgT;
end

if display
    figure('Name', 'Level set segmentation');
    title('Initial contour');
end

u1 = zeros(nrows, ncols);
tStart = tic;
for n = 1:Iter
    % Convergence condition
    if (n > 1 && isequal(u1,u))
        break;
    end
    u1 = u;
    
    [ux, uy] = gradient(u);
    
    % Global Information Term calculation
    m1 = nanmedian(ImgAi(u>=0));
    c2 = nanmean(ImgAo(u<0));
    c1 = nanmean(ImgAi(u>=0));
    if noMedian
        m1=c2;
    end
    EGLOBAL1 = -(ImgAi-c1).^2-(ImgAi-m1).^2+2*(ImgAo-c2).^2;
    if noMedian
        EGLOBAL1 = (1/2)*EGLOBAL1;
    end
    
    m12 = nanmedian(ImgBi(u>=0));
    c22 = nanmean(ImgBo(u<0));
    c12 = nanmean(ImgBi(u>=0));
    if noMedian
        m12=c22;
    end
    EGLOBAL2 = -(ImgBi-c12).^2-(ImgBi-m12).^2+2*(ImgBo-c22).^2;
    if noMedian
        EGLOBAL2 = (1/2)*EGLOBAL2;
    end
    
    m13 = nanmedian(ImgTi(u>=0));
    c23 = nanmean(ImgTo(u<0));
    c13 = nanmean(ImgTi(u>=0));
    if noMedian
        m13=c23;
    end
    EGLOBAL3 = -(ImgTi-c13).^2-(ImgTi-m13).^2+2*(ImgTo-c23).^2;
    if noMedian
        EGLOBAL3 = (1/2)*EGLOBAL3;
    end
    
    m14 = median(ImgA(u>=0));
    c24 = nanmean(ImgA(u<0));
    c14 = nanmean(ImgA(u>=0));
    if noMedian
        m14=c24;
    end
    EGLOBAL4 = -(ImgA-c14).^2-(ImgA-m14).^2+2*(ImgA-c24).^2;
    if noMedian
        EGLOBAL4 = (1/2)*EGLOBAL4;
    end
    
    m15 = median(ImgB(u>=0));
    c25 = nanmean(ImgB(u<0));
    c15 = nanmean(ImgB(u>=0));
    if noMedian
        m15=c25;
    end
    EGLOBAL5 = -(ImgB-c15).^2-(ImgB-m15).^2+2*(ImgB-c25).^2;
    if noMedian
        EGLOBAL5 = (1/2)*EGLOBAL5;
    end
    
    m16 = nanmedian(ImgT(u>=0));
    c26 = nanmean(ImgT(u<0));
    c16 = nanmean(ImgT(u>=0));
    if noMedian
        m16=c26;
    end
    EGLOBAL6 = -(ImgT-c16).^2-(ImgT-m16).^2+2*(ImgT-c26).^2;
    if noMedian
        EGLOBAL6 = (1/2)*EGLOBAL6;
    end
    
    EGLOBAL = lambda * (1/3) *(EGLOBAL1 + EGLOBAL2 + EGLOBAL3) + (1-lambda) * (1/3) * (EGLOBAL4 + EGLOBAL5 + EGLOBAL6);
    u = u + (EGLOBAL .* sqrt(ux.^2 + uy.^2));
    
    if display && mod(n, 10) == 0
        imagesc(I, [0 255]); colormap(gray); hold on;
        contour(u, [0 0], 'r', 'LineWidth', 1);
        iterNum = [num2str(n), 'iterations'];
        title(iterNum);
        pause(0.1);
    end
    
    u = (u >= 0) - (u < 0);
    u = conv2(u, G, 'same');
end
tElapsed = toc(tStart);
if display
    fprintf('Elapsed time (s): %.3f\n', tElapsed);
end
if display
    imshow(I, 'initialmagnification', 200, 'displayrange', [0 255]);
    hold on;
    contour(u, [0 0], 'r', 'LineWidth', 2);
    hold off;
    title([num2str(n) ' Iterations']);
    drawnow;
end

% Segmentation result
mask = false(nrows, ncols);
mask(u >= 0) = true;

end
