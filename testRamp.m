%% testRamp
% Verify the frictional-ramp physics engine before connecting it to a GUI.
% The script runs three representative cases, checks the expected motion,
% prints the initial/final states, and plots the primary case.

clear
clc
close all

caseNames = ["Slides from rest", "Remains at rest", "Moves up then reverses"];
masses = [1.0, 1.0, 2.0];                  % kg
frictionCoefficients = [0.4, 0.6, 0.4];
rampAngles = [25.0, 25.0, 25.0];          % degrees
initialPositions = [3.0, 3.0, 3.0];       % m along ramp
initialVelocities = [0.0, 0.0, 2.0];      % m/s; positive is up ramp

results = repmat(struct( ...
    'time', [], 'position', [], 'velocity', [], 'energy', []), ...
    1, numel(caseNames));

fprintf('FRICTIONAL RAMP VERIFICATION\n');
fprintf('Positive position and velocity point up the ramp.\n\n');

for caseIndex = 1:numel(caseNames)
    [time, position, velocity, energy] = simulateRamp( ...
        masses(caseIndex), ...
        frictionCoefficients(caseIndex), ...
        rampAngles(caseIndex), ...
        initialPositions(caseIndex), ...
        initialVelocities(caseIndex));

    results(caseIndex).time = time;
    results(caseIndex).position = position;
    results(caseIndex).velocity = velocity;
    results(caseIndex).energy = energy;

    maximumEnergyError = max(abs(energy.balanceError));

    fprintf('Case %d: %s\n', caseIndex, caseNames(caseIndex));
    fprintf('  Parameters: m = %.2f kg, mu = %.2f, theta = %.2f deg\n', ...
        masses(caseIndex), frictionCoefficients(caseIndex), ...
        rampAngles(caseIndex));
    fprintf('  Initial:    t = %7.4f s, s = %8.4f m, v = %8.4f m/s\n', ...
        time(1), position(1), velocity(1));
    fprintf('  Final:      t = %7.4f s, s = %8.4f m, v = %8.4f m/s\n', ...
        time(end), position(end), velocity(end));
    fprintf('  Initial energy:        %12.8f J\n', ...
        energy.accountedTotal(1));
    fprintf('  Final accounted energy:%12.8f J\n', ...
        energy.accountedTotal(end));
    fprintf('  Maximum energy error:  %12.3e J\n\n', ...
        maximumEnergyError);

    assert(maximumEnergyError < 1.0e-9, ...
        'Case %d failed the energy-balance check.', caseIndex);
end

% Case-specific behavior checks.
assert(results(1).position(end) == 0 && results(1).velocity(end) < 0, ...
    'Case 1 should slide down and reach the bottom of the ramp.');

assert(isscalar(results(2).time) && results(2).velocity(end) == 0, ...
    'Case 2 should remain at rest because friction supports the box.');

assert(max(results(3).position) > initialPositions(3) && ...
       results(3).position(end) == 0 && results(3).velocity(end) < 0, ...
    'Case 3 should move up, reverse direction, and reach the bottom.');

fprintf('All ramp verification checks passed.\n');

%% Plot Case 1
plotCase = 1;
time = results(plotCase).time;
position = results(plotCase).position;
velocity = results(plotCase).velocity;
energy = results(plotCase).energy;

figure('Name', 'Frictional Ramp Verification', 'Color', 'white');
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile
plot(time, position, 'LineWidth', 1.8, 'Color', [0.12 0.42 0.78]);
grid on
xlabel('Time (s)')
ylabel('Position (m)')
title('Position Along Ramp')

nexttile
plot(time, abs(velocity), 'LineWidth', 1.8, 'Color', [0.88 0.36 0.18]);
grid on
xlabel('Time (s)')
ylabel('Speed (m/s)')
title('Speed')

nexttile
plot(time, energy.kinetic, 'LineWidth', 1.6)
hold on
plot(time, energy.potential, 'LineWidth', 1.6)
plot(time, energy.frictionDissipated, 'LineWidth', 1.6)
plot(time, energy.accountedTotal, 'k--', 'LineWidth', 1.8)
hold off
grid on
xlabel('Time (s)')
ylabel('Energy (J)')
title('Energy Transformation and Conservation')
legend('Kinetic', 'Potential', 'Friction dissipated', ...
    'Mechanical + dissipated', 'Location', 'best')

title(layout, sprintf( ...
    'Ramp Test: m = %.1f kg, \\mu = %.1f, \\theta = %.0f^\\circ', ...
    masses(plotCase), frictionCoefficients(plotCase), ...
    rampAngles(plotCase)))
