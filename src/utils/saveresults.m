function saveresults(Struct, Save, Mod)
    % SAVERESULTS Save the fields of a strucure in a MAT-file, according to user's config.
    %   This function saves the fields of the input structure 'Struct' as individual variables,
    %   following the user's configuration defined rules for the file naming.
    % -----
    %
    % Syntax:
    %   saveresults(Struct, Save, Mod) Saves each field of the input Struct as individual variables
    %   in a MAT-File, following the configuration options described in Sim.Save and Mod
    %   (see configs/template.m).
    %
    % Inputs:
    %   Struct : Struct whose fileds will be saved
    %   Save   : Save options (see Sim.Save structure)
    %   Mod    : Model configuration (see Mod structure)
    %
    % Outputs:
    %   MAT-file with the Struct fields as variables.
    %
    % See also: rotare, template.
    %
    % <a href="https://gitlab.uliege.be/rotare/documentation">Complete documentation (online)</a>

    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 2022-2023 University of Liege
    % Author: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    % MIT License
    % Repo: https://gitlab.uliege.be/rotare/rotare
    % Docs: https://gitlab.uliege.be/rotare/documentation
    % Issues: https://gitlab.uliege.be/rotare/rotare/-/issues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Create directory for the results if it does not exist
    if ~isfolder(Save.dir)
        mkdir(Save.dir);
    end

    % Generate proper name based on user inputs
    filename = formatfilename(Save, Mod);

    % Save to file
    save([Save.dir, filename, '.mat'], '-struct', 'Struct');

end

function filename = formatfilename(Save, Mod)
    % FORMATFILENAME Format the filename using user configuration preferences.

    filename = Save.filename;

    % Ensure user did not put an extension already
    [path, file, ~] = fileparts(filename);
    filename = fullfile(path, file);

    % Append the solver name and loss model to the file name
    if Save.appendInfo
        filename = [filename, '_', Mod.solver, '_', Mod.Ext.losses];
    end

    % Prepend the file name with a timestamp
    if Save.prependTime
        timestamp = datestr(datetime('now'), Save.timeFormat);
        filename = [timestamp, '-', filename];
    end

    % Prevent overwriting file
    if ~Save.overwrite
        baseFilename = filename;
        i = 0;
        while isfile([Save.dir, filename, '.mat'])
            i = i + 1;
            filename = [baseFilename, '_v', num2str(i)];
        end
    end

end
