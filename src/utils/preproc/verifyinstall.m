function bool = verifyinstall
    % VERIFYINSTALL Verifies proper installation of Rotare.
    %   This function checks if all functions and libraries are available and in Matlab's path
    %   before executing the code.
    %   It also checks if rotare is run on Matlab and not Octave.
    % -----
    %
    % List of functions/classes expected to be found:
    %   - atmosisa: From Matlab's aerospace toolbox or from github.com/lentzi90/octave-atmosisa
    %   - af_tools.Airfoil: From af_tools library
    %   - af_tools.Polar: From af_tools library
    %
    % See also: rotare, af_tools.Airfoil, af_tools.Polar.
    %
    % <a href="https://gitlab.uliege.be/thlamb/rotare-doc">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/thlamb/rotare
    % Docs: https://gitlab.uliege.be/thlamb/rotare-doc
    % Issues: https://gitlab.uliege.be/thlamb/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    persistent bool_ % Prevent future checks if all is good

    if isempty(bool_)
        try
            % Check for Octave
            if isoctave
                warning('off', 'backtrace');
                warning('Rotare:verifyinstall:octave', ...
                        ['You seem to be running Rotare using Octave.\n' ...
                         'Rotare has not been tested on Octave. As it relies heavily on the '...
                         'OOP capabilities of Matlab -which are not fully implemented in ' ...
                         'Octave- it may not be working as expected.\n\n'...
                         'A proper support for Octave and extensive testing is on the roadmap, ' ...
                         'but not very high priority at the moment. Sorry for the inconvenience.'...
                         ' Any merge request in that direction would be greatly appreciated.\n']);
                warning('on', 'backtrace');
            end

            % Check for atmosisa
            if ~exist('atmosisa', 'file')
                warning('off', 'backtrace');
                warning('Rotare:verifyinstall:missingAtmosisa', ...
                        ['Function atmosisa not found.\n' ...
                         'Rotare uses the ''atmosisa'' function in order to determine properly '...
                         'the air properties with respect to the current altitude. '...
                         'As this function was not found on your system, the default values for '...
                         'air at 15°C and 0m altitude will be used.\n' ...
                         'For more precise results, you can get the Matlab aerospace '...
                         'toolbox or download an open-source version of that function here: ' ...
                         '<a href="https://github.com/lentzi90/octave-atmosisa">'...
                         'https://github.com/lentzi90/octave-atmosisa</a>.\n']);
                warning('on', 'backtrace');
            end

            % Check for af_tools functions
            checkaftools('af_tools.Airfoil');
            checkaftools('af_tools.Polar');

            % Return true if all checks were passed
            bool_ = true;

        catch ME
            rethrow(ME);
        end
    end

    bool = bool_;

end

function checkaftools(fctname)
    % CHECKAFTOOLS Check if af_tools function or classes are available

    if ~(exist(fctname, 'class') || exist(fctname, 'file'))
        Error.identifier = 'Rotare:verifyinstall:missingAfTools';
        Error.message = ...
            sprintf(['Error: Function %s not found.\n' ...
                     'Rotare requires the ''af_tools'' library to determine airfoil properties '...
                     'and the corresponding polars.\n' ...
                     'It seems that at least some parts of this library are missing.\n'...
                     'Please download '...
                     '<a href="https://gitlab.uliege.be/am-dept/matlab_airfoil_toolbox">'...
                     'the following library</a> and place it somewhere on Matlab''s path.\n\n' ...
                     'Check the <a href="https://gitlab.uliege.be/thlamb/rotare-doc">complete '...
                     'documentation (online)</a> for help on how to install properly all '...
                     'dependencies.'], fctname);
        Error.stack.file = '';
        Error.stack.name = 'verifyinstall';
        Error.stack.line = 1;
        error(Error);
    end

end
