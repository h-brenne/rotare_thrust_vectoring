function bool = isoctave
    % ISOCTAVE Checks if function was called in Octave or Matlab
    %   This function returns true if it is called in Octave, false otherwise.

    % ----------------------------------------------------------------------------------------------
    % Ref: https://docs.octave.org/latest/How-to-Distinguish-Between-Octave-and-Matlab.html
    % ----------------------------------------------------------------------------------------------
    % (c) Copyright 1996-2022 The Octave Project Developers
    %   Permission is granted to make and distribute verbatim copies of this manual provided the
    %   copyright notice and this permission notice are preserved on all copies.
    %   Permission is granted to copy and distribute modified versions of this manual under the
    %   conditions for verbatim copying, provided that the entire resulting derived work is
    %   distributed under the terms of a permission notice identical to this one.
    %   Permission is granted to copy and distribute translations of this manual into another
    %   language, under the above conditions for modified versions.
    %
    % Adapted from the official octave docs at https://docs.octave.org/latest (Appendix D.4)
    % Modified by: Thomas Lambert <t.lambert@uliege.be>
    % ULiege - Aeroelasticity and Experimental Aerodynamics
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    persistent bool_  % Speeds up repeated calls

    if isempty (bool_)
        bool_ = (exist('OCTAVE_VERSION', 'builtin') > 0);
    end

    bool = bool_;

end
