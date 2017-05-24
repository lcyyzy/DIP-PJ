function featVec = selectImageFeatures(featStruct, varargin)


%% Parse arguments
defaultArgs = struct('RGBContrastACM', 0, 'RGBContrastKe', 0);
args = parseargs(defaultArgs, varargin{:});

featVec = [];

%% Create feature vector
columnInd = {[], 1};

% RGB contrast
featVec = cat(2, featVec, featStruct.RGBContrast.acm(columnInd{args.RGBContrastACM+1}));
featVec = cat(2, featVec, featStruct.RGBContrast.ke(columnInd{args.RGBContrastKe+1}));

