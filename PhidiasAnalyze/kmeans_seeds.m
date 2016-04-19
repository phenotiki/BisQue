function seeds = kmeans_seeds(img, X)
%KMEANS_SEEDS Calculates foreground/background seeds for k-means clustering.
%
%   Input:
%       img - RGB image
%         X - features
%
%   Output:
%     seeds - foreground/background seeds
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

% Trasform the RGB to Excess Green (ExG) domain
img_double = double(img);
ExG = 2*img_double(:,:,2) - img_double(:,:,1) - img_double(:,:,3);

% Segment ExG image into 2 classes by means of Otsu's N-thresholding method
[Idx, ~] = otsu(ExG(:), 2);

% K-means seeds for a* and b* components in L*a*b* colour space
% Seeds are found by averaging foreground and background pixels, respectively
seeds = [mean(X(Idx == 2, :)); mean(X(Idx == 1, :))];

end
