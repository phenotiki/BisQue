function d = grid_search_dsc(GTM, GSM, session)
% This function computes the Dice coefficient between the labelled masks
% created by the algorithm (GSM) and the ground truth images (GTM) and returns d as the
% average coefficient for the current grid search iteration

sum = 0;

S = size(GSM, 1);

for i = 1:S
    GT = GTM{i,1};
    img_name = GTM{i,2};
    [~, row_idx] = ismember(img_name, GSM(:,2));
    try
        AR = GSM{row_idx,1};
    catch
        fprintf('Image not found.\n');
        outputs = session.mex.addTag('outputs');  
        errors = outputs.addTag('errors');
        errors.addTag(sprintf('Image not found.\n'));
        session.update('Terminating..');
        session.finish();
        return;
    end
    AR = logical(AR);
    GT = logical(GT);
    DSC = (2*nnz(GT & AR))/(nnz(GT) + nnz(AR));
    fprintf('\n\n----- (Label %d: dice = %.3f) -----\n', i, DSC);
    sum = sum + DSC;
end

d = sum / S;
fprintf('\n\n----- (Mean dice = %.3f) -----\n', d);
end