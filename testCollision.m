%% testCollision
% Verify all three collision models before connecting them to a GUI.
% The script checks momentum, restitution, and energy accounting, then
% plots a frictional imperfectly inelastic collision.

clear
clc
close all

% Shared initial conditions. Object 1 begins to the left and catches
% object 2. Positive position and velocity point to the right.
m1 = 3.0;                 % kg
m2 = 1.0;                 % kg
x1Initial = 0.0;          % m
x2Initial = 1.0;          % m
u1 = 2.0;                 % m/s
u2 = 1.0;                 % m/s
g = 9.81;                 % m/s^2

caseNames = ["Perfectly elastic", ...
             "Perfectly inelastic", ...
             "Imperfectly inelastic with friction"];
collisionTypes = ["elastic", ...
                  "perfectly inelastic", ...
                  "imperfectly inelastic"];
restitutionValues = [1.0, 0.0, 0.5];
frictionCoefficients = [0.0, 0.0, 0.05];

results = repmat(struct( ...
    'time', [], 'position', [], 'velocity', [], 'momentum', [], ...
    'energy', [], 'collision', []), 1, numel(caseNames));

fprintf('ONE-DIMENSIONAL COLLISION VERIFICATION\n');
fprintf('Positive position and velocity point to the right.\n\n');

for caseIndex = 1:numel(caseNames)
    [time, position, velocity, momentum, energy, collision] = ...
        simulateCollision(m1, m2, x1Initial, x2Initial, u1, u2, ...
        collisionTypes(caseIndex), restitutionValues(caseIndex), ...
        frictionCoefficients(caseIndex), g);

    results(caseIndex).time = time;
    results(caseIndex).position = position;
    results(caseIndex).velocity = velocity;
    results(caseIndex).momentum = momentum;
    results(caseIndex).energy = energy;
    results(caseIndex).collision = collision;

    maximumEnergyError = max(abs(energy.balanceError));

    fprintf('Case %d: %s\n', caseIndex, caseNames(caseIndex));
    fprintf('  Parameters: e = %.2f, mu = %.2f\n', ...
        collision.restitution, frictionCoefficients(caseIndex));
    fprintf('  Collision:  t = %.6f s, x = %.6f m\n', ...
        collision.time, collision.position);
    fprintf('  Velocity before: [%9.6f, %9.6f] m/s\n', ...
        collision.velocityBefore(1), collision.velocityBefore(2));
    fprintf('  Velocity after:  [%9.6f, %9.6f] m/s\n', ...
        collision.velocityAfter(1), collision.velocityAfter(2));
    fprintf('  Momentum before: %12.8f kg*m/s\n', ...
        collision.momentumBefore);
    fprintf('  Momentum after:  %12.8f kg*m/s\n', ...
        collision.momentumAfter);
    fprintf('  Momentum error:  %12.3e kg*m/s\n', ...
        collision.momentumError);
    fprintf('  KE before:       %12.8f J\n', ...
        collision.kineticEnergyBefore);
    fprintf('  KE after:        %12.8f J\n', ...
        collision.kineticEnergyAfter);
    fprintf('  Collision loss:  %12.8f J\n', ...
        collision.energyLost);
    fprintf('  Max energy error:%12.3e J\n\n', maximumEnergyError);

    assert(collision.occurred, ...
        'Case %d did not produce a collision.', caseIndex);
    assert(abs(collision.momentumError) < 1.0e-10, ...
        'Case %d failed momentum conservation at impact.', caseIndex);
    assert(maximumEnergyError < 1.0e-8, ...
        'Case %d failed total energy accounting.', caseIndex);

    relativeSpeedBefore = collision.velocityBefore(1) - ...
        collision.velocityBefore(2);
    relativeSpeedAfter = collision.velocityAfter(2) - ...
        collision.velocityAfter(1);
    measuredRestitution = relativeSpeedAfter / relativeSpeedBefore;
    assert(abs(measuredRestitution - collision.restitution) < 1.0e-10, ...
        'Case %d failed the coefficient-of-restitution check.', caseIndex);
end

% Known analytical results for m1 = 3 kg, m2 = 1 kg, u1 = 2 m/s,
% and u2 = 1 m/s on a frictionless surface.
assert(max(abs(results(1).collision.velocityAfter - [1.5, 2.5])) ...
    < 1.0e-12, 'The elastic collision result is incorrect.');
assert(max(abs(results(2).collision.velocityAfter - [1.75, 1.75])) ...
    < 1.0e-12, 'The perfectly inelastic collision result is incorrect.');

fprintf('All collision verification checks passed.\n');

%% Plot Case 3: imperfectly inelastic collision with surface friction
plotCase = 3;
time = results(plotCase).time;
position = results(plotCase).position;
velocity = results(plotCase).velocity;
momentum = results(plotCase).momentum;
energy = results(plotCase).energy;
collision = results(plotCase).collision;

figure('Name', 'Collision Verification', 'Color', 'white');
layout = tiledlayout(2, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile
plot(time, position(:, 1), 'LineWidth', 1.7)
hold on
plot(time, position(:, 2), 'LineWidth', 1.7)
xline(collision.time, 'k--', 'Collision', 'LineWidth', 1.2)
hold off
grid on
xlabel('Time (s)')
ylabel('Position (m)')
title('Position')
legend('Object 1', 'Object 2', 'Location', 'best')

nexttile
plot(time, abs(velocity(:, 1)), 'LineWidth', 1.7)
hold on
plot(time, abs(velocity(:, 2)), 'LineWidth', 1.7)
xline(collision.time, 'k--', 'Collision', 'LineWidth', 1.2)
hold off
grid on
xlabel('Time (s)')
ylabel('Speed (m/s)')
title('Speed')
legend('Object 1', 'Object 2', 'Location', 'best')

nexttile
plot(time, momentum.object(:, 1), 'LineWidth', 1.6)
hold on
plot(time, momentum.object(:, 2), 'LineWidth', 1.6)
plot(time, momentum.total, 'k--', 'LineWidth', 1.8)
xline(collision.time, 'k:', 'Collision', 'LineWidth', 1.2)
hold off
grid on
xlabel('Time (s)')
ylabel('Momentum (kg*m/s)')
title('Momentum')
legend('Object 1', 'Object 2', 'Total', 'Location', 'best')

nexttile
plot(time, energy.totalKinetic, 'LineWidth', 1.6)
hold on
plot(time, energy.totalFrictionDissipated, 'LineWidth', 1.6)
plot(time, energy.collisionLoss, 'LineWidth', 1.6)
plot(time, energy.accountedTotal, 'k--', 'LineWidth', 1.8)
xline(collision.time, 'k:', 'Collision', 'LineWidth', 1.2)
hold off
grid on
xlabel('Time (s)')
ylabel('Energy (J)')
title('Energy Transformation')
legend('Total kinetic', 'Friction dissipated', 'Collision loss', ...
    'Accounted total', 'Location', 'best')

title(layout, sprintf( ...
    'Collision Test: m_1 = %.1f kg, m_2 = %.1f kg, e = %.1f, \\mu = %.2f', ...
    m1, m2, collision.restitution, frictionCoefficients(plotCase)))
