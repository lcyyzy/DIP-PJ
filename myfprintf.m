function ret = myfprintf(varargin)

if ischar(varargin{1})
    doDisplay = 1;
    str = varargin{1};
    args = varargin(2:end);
else
    doDisplay = varargin{1};
    str = varargin{2};
    args = varargin(3:end);
end

r = 0;
if doDisplay
    r = fprintf(str, args{:});
end

if nargout
    ret = r;
end

