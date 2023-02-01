function plot(self, type)
    % PLOT Plot the evolution of the various properties along the span.
    %   This method plots the evolution of the various ElemPerf properties along the span of the
    %   blade.
    % -----
    %
    % Syntax:
    %   ElPerf.plot() plots all possible figures.
    %
    %   ElPerf.plot(type) plots the figures according to the cell array 'type'.
    %
    % Inputs:
    %   type: Type of plot to output (cell array). Type can be:
    %       - reynolds   : Reynolds number
    %       - angles     : Pitch, angle of attack
    %       - speeds : Inflow/swirl ratios, Induced inflow/swirl ratios, Induced velocities (ax/tg)
    %       - aeroforces : cl, cd, dL, dD
    %       - dT         : dT
    %       - dQ         : dQ
    %       - power      : dPi, dPp, dP
    %       - all        : all the above. Equivalent to ElPerf.plot()
    %
    % Outputs:
    %    Plots of the evolution of ElemPerf properties along the span.
    %
    % Examples:
    %   ElPerf.plot()
    %   ElPerf.plot('reynolds')
    %   ElPerf.plot({'reynolds', 'angles', 'dT', 'power'})
    %
    % See also: ElemPerf.
    %
    % <a href="https:/gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Defaults and constants
    DEF.ALLOWED_TYPES = {'reynolds', 'angles', 'speeds', 'aeroforces', ...
                         'dT', 'dQ', 'power', 'all'};
    DEF.ANGLES_PROP = {'pitch', 'alpha', 'inflAngle'};
    DEF.AEROFORCES_PROP = {'cl', 'cd'; 'dL', 'dD'};
    DEF.POWER_PROP = {'dPi', 'dPp', 'dP'};
    DEF.SPEEDS_PROP = {'inflowRat', 'swirlRat'; ...
                       'indInflowRat', 'indSwirlRat'; ...
                       'indVelAx', 'indVelTg'};

    % Input checks
    if nargin < 2
        type = 'all';
    end

    type = formatandcheck(type, DEF);

    % Get the exact properties to plot
    [singlePlots, doublePlots] = getproptoplot(type, DEF);

    % Plot properties
    for i = 1:length(singlePlots)
        prop = singlePlots{i};
        singleplot(self, prop);
    end

    for j = 1:size(doublePlots, 2)
        props = doublePlots(j, :);
        doubleplot(self, props);
    end

end

function type = formatandcheck(type, Def)
    % FORMATANDCHECK Format and check the 'type' variable.

    % Convert everything to cell array for simpler processing
    if ischar(type)
        type = cellstr(type);
    end

    % Check input validity
    for iType = 1:length(type)
        type{iType} = validatestring(type{iType}, Def.ALLOWED_TYPES, mfilename(), 'type');
    end

    % Replace 'all' by complete list
    if any(strcmp(type, 'all'))
        type = Def.ALLOWED_TYPES;
        type(strcmp(Def.ALLOWED_TYPES, 'all')) = [];
    end

end

function [singlePlots, doublePlots] = getproptoplot(type, Def)
    % GETPROPTOPLOT Get the list of the exact properties to plot.

    singlePlots = cell(0);
    doublePlots = cell(0);

    for i = 1:length(type)
        prop = type{i};

        switch prop
            case {'reynolds', 'dT', 'dQ'}
                singlePlots{end + 1} = prop;
            case 'angles'
                singlePlots = [singlePlots, Def.ANGLES_PROP];
            case 'speeds'
                doublePlots = [doublePlots; Def.SPEEDS_PROP];
            case 'aeroforces'
                doublePlots = [doublePlots; Def.AEROFORCES_PROP];
            case 'power'
                singlePlots{end + 1} = 'dP';
        end

    end

end

function singleplot(self, propName)
    % SINGLEPLOT Plot for single properties.

    if ~isempty(self.(propName))
        figure('Name', propName);
        if any(strcmp(propName, {'pitch', 'alpha'}))
            plot(self.Rot.Bl.r, rad2deg(self.(propName)));
        else
            plot(self.Rot.Bl.r, self.(propName));
        end
        xlabel('Spanwise relative position, r/R [-]');
        ylabel(getlabel(propName));
        setgca();
    else
        warning('Rotare:ElPerf:plot:emptyProperty', ...
                ['The property %s cannot be plotted as it is currently empty.\n' ...
                 'Make sure all ElPerf properties are evaluated before trying to plot them. '...
                 'This can be done by running ''ElPerf.calcforces'' if the angle of attack ' ...
                 '(ElPerf.alpha) of each element is known.'], propName);
    end

end

function doubleplot(self, propNames)
    % DOUBLEPLOT Plot for properties that go together (e.g., cl, cd).

    if ~isempty(self.(propNames{1})) && ~isempty(self.(propNames{2}))
        figure('Name', [propNames{1}, ' and ', propNames{2}]);
        yyaxis left;
        plot(self.Rot.Bl.r, self.(propNames{1}));
        xlabel('Spanwise relative position, r/R [-]');
        ylabel(getlabel(propNames{1}));
        setgca(true);

        yyaxis right;
        plot(self.Rot.Bl.r, self.(propNames{2}));
        ylabel(getlabel(propNames{2}));
        setgca(true);
    else
        warning('Rotare:ElPerf:plot:emptyProperty', ...
                ['The properties %s and %s cannot be plotted as at least one is empty.\n' ...
                 'Make sure all ElPerf properties are evaluated before trying to plot them. '...
                 'This can be done by running ''ElPerf.calcforces'' if the angle of attack ' ...
                 '(ElPerf.alpha) of each element is known.'], propNames{1}, propNames{2});
    end
end

function setgca(isDouble)
    % SETGCA Uniform setup for graphs axes.

    if nargin == 0
        isDouble = false;
    end

    set(gca, ...
        'FontName', 'Helvetica', ...
        'Fontsize', 14, ...
        'Box', 'off', ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'off', ...
        'TickDir', 'out', ...
        'TickLength', [.02 .02], ...
        'XGrid', 'on', ...
        'YGrid', 'on', ...
        'XColor', 'k', ...
        'GridLineStyle', ':', ...
        'GridColor', 'k', ...
        'GridAlpha', 0.25, ...
        'LineWidth', 1);

    % Specific tweaks if graph is for single properties
    if ~isDouble
        set(gca, 'YColor', 'k');
    end

    set(gcf, 'PaperPositionMode', 'auto');

end

function lab = getlabel(prop)
    % GETLABEL Returns the label corresponding to the property.

    % Table of labels
    TABLE = {'reynolds', 'Reynolds, Re [-]'
             'pitch', 'Pitch angle, \theta [deg]'
             'alpha', 'Angle of attack, \alpha [deg]'
             'inflAngle', 'Inflow angle, \phi [deg]'
             'inflowRat', 'Inflow ratio, \lambda [-]'
             'swirlRat', 'Swirl ratio, \xi [-]'
             'indInflowRat', 'Induced inflow ratio, \lambda_i [-]'
             'indSwirlRat', 'Induced swirl ratio, \xi_i [-]'
             'indVelAx', 'Axial induced velocity, v_i [m/s]'
             'indVelTg', 'Tangential induced velocity, u_i [m/s]'
             'cl', 'Lift coefficient, cl [-]'
             'cd', 'Drag coefficient, cd [-]'
             'dL', 'Lift, dL [N]'
             'dD', 'Drag, dD [N]'
             'dT', 'Thrust, dT [N]'
             'dQ', 'Torque, dQ [N.m]'
             'dPi', 'Induced power, dPi [W]'
             'dPp', 'Profile power, dPp [W]'
             'dP', 'Power, dP [W]'};

    lab = TABLE{strcmp(TABLE(:, 1), prop), 2};
end
