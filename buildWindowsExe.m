function results = buildWindowsExe
%BUILDWINDOWSEXE Build MechanicsLearningLab.exe on a Windows computer.
%
% Requirements:
%   - Microsoft Windows
%   - MATLAB R2025a or a compatible release
%   - MATLAB Compiler
%
% Run this function from the repository root. Each build is written to a
% timestamped subfolder under build/ so an earlier build is not overwritten.

    if ~ispc
        error('buildWindowsExe:WindowsRequired', ...
            ['A Windows executable must be built on Windows. Clone this ', ...
             'repository on a Windows computer and run buildWindowsExe there.']);
    end

    if exist('compiler.build.standaloneWindowsApplication', 'file') ~= 2
        error('buildWindowsExe:CompilerRequired', ...
            ['MATLAB Compiler is not installed or licensed. Install MATLAB ', ...
             'Compiler, restart MATLAB, and run this function again.']);
    end

    projectRoot = fileparts(mfilename('fullpath'));
    requiredFiles = [ ...
        "launchPhysicsTeachingApp.m", ...
        "PhysicsTeachingApp.m", ...
        "simulateRamp.m", ...
        "simulateCollision.m"];

    missingFiles = requiredFiles(~isfile(fullfile(projectRoot, requiredFiles)));
    if ~isempty(missingFiles)
        error('buildWindowsExe:MissingFiles', ...
            'Missing required files: %s', strjoin(missingFiles, ', '));
    end

    buildStamp = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    outputDirectory = fullfile(projectRoot, 'build', ...
        "windows_" + buildStamp);

    results = compiler.build.standaloneWindowsApplication( ...
        fullfile(projectRoot, 'launchPhysicsTeachingApp.m'), ...
        'ExecutableName', 'MechanicsLearningLab', ...
        'AdditionalFiles', fullfile(projectRoot, requiredFiles(2:end)), ...
        'OutputDir', outputDirectory);

    fprintf('\nWindows build completed.\n');
    fprintf('Output directory:\n  %s\n\n', outputDirectory);
    fprintf('Generated files:\n');
    for fileIndex = 1:numel(results.Files)
        fprintf('  %s\n', results.Files{fileIndex});
    end
end
