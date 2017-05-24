function [meanBndInterpVal, bndInterpVal] = interpBoundarySubPixel(boundaries, interpMap)


% compute probability of ground at each boundary point
boundariesCat = max(cat(1, boundaries{:}), 1);
boundariesCatInterpVal = interp2(1:size(interpMap,2), 1:size(interpMap,1), ...
    double(interpMap), min(boundariesCat(:,1), size(interpMap,2)), min(boundariesCat(:,2), size(interpMap,1)));

% compute mean for each boundary line
boundariesLength = cellfun(@(x) length(x), boundaries);
boundariesCumsum = [0 cumsum(boundariesLength)];
boundariesLineInd = arrayfun(@(i) boundariesCumsum(i)+1:boundariesCumsum(i+1), 1:(length(boundariesCumsum)-1), 'UniformOutput', 0);

bndInterpVal = cellfun(@(x) boundariesCatInterpVal(x), boundariesLineInd, 'UniformOutput', 0);
meanBndInterpVal = cellfun(@(x) mean(x), bndInterpVal);

