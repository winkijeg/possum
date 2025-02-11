function h = plot_contour(obj, contType, contName, col, h_axes, funcHandle)
% plot the two traces which were manually determined
    % this method plots contour only if the positions are non-empty
    %    
    %input arguments:
    %
    %   - col       : color, i.e. 'r' for red, or [1 0 0] ( RGB - triple )
    %   - h_axes    : axes handle of the window to be plotted to
    %
 
    if ~exist('col', 'var') || isempty(col)
        col = 'k';
    end

    if ~exist('h_axes', 'var') || isempty(h_axes)
        h_axes = obj.initPlotFigure(false);
    end
    
    modus = 'edit';
    if ~exist('funcHandle', 'var') || isempty(funcHandle)
        funcHandle = '';
        modus = 'plain';
    end
    
    if strcmp(contType, 'raw')
        switch contName
            case 'inner'
                xValsTmp = obj.xyInnerTrace_raw(1, :);
                yValsTmp = obj.xyInnerTrace_raw(2, :);
            case 'outer'
                xValsTmp = obj.xyOuterTrace_raw(1, :);
                yValsTmp = obj.xyOuterTrace_raw(2, :);
        end
    else
        switch contName
            case 'inner'
                xValsTmp = obj.xyInnerTrace_sampl(1, :);
                yValsTmp = obj.xyInnerTrace_sampl(2, :);
            case 'outer'
                xValsTmp = obj.xyOuterTrace_sampl(1, :);
                yValsTmp = obj.xyOuterTrace_sampl(2, :);
        end
    end
    
 
    if ~isempty(xValsTmp)
        switch modus
            case 'plain'
                h = plot(h_axes, xValsTmp, yValsTmp, 'w-', 'LineWidth', 1);
            case 'edit'
                nPoints = size(xValsTmp, 2);
                for nbPoint = 1:nPoints
                    h(nbPoint) = plot(h_axes, xValsTmp(nbPoint), yValsTmp(nbPoint), ...
                        'Color', col, 'Marker', 'o', 'MarkerFaceColor', [0.75 0.75 0.75], ...
                        'Tag', int2str(nbPoint), 'ButtonDownFcn', funcHandle);
                end
        end
    else
        h = gobjects(1);
    end
       
end
