function [wseg, curIter] = grad2wseg(gradImage, prctMaxNbSegs)

if nargin == 1
    prctMaxNbSegs = 1;
end

c = 1;
maxNbIter = 10;
curIter = 1;

wseg = watershed(medfilt2(gradImage, [c c]));
maxNbSegs = max(wseg(:));

nbSegs = maxNbSegs;

while nbSegs > maxNbSegs*prctMaxNbSegs && curIter <= maxNbIter
    c = c + 2;
    wseg = watershed(medfilt2(gradImage, [c c]));
    nbSegs = max(wseg(:));
    curIter = curIter + 1;
end
wseg = uint16(wseg);