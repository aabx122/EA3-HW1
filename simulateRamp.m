function [time, position, velocity, energy] = ...
        simulateRamp(m, mu, thetaDeg, x0, v0, maxTime)
%SIMULATERAMP Simulate a box moving on a frictional ramp.
%
%   [TIME, POSITION, VELOCITY, ENERGY] = SIMULATERAMP(M, MU, THETADEG,
%   X0, V0) simulates a box on a fixed ramp using a 0.01 s time step.
%   An optional sixth input specifies the maximum simulation time in
%   seconds; its default value is 30 seconds.
%
%   Coordinate convention:
%       POSITION is measured along the ramp.
%       Positive POSITION and VELOCITY point up the ramp.
%       POSITION = 0 is the bottom of the ramp.
%
%   Inputs:
%       m         Box mass in kg
%       mu        Coulomb friction coefficient
%       thetaDeg  Ramp angle in degrees
%       x0        Initial position along the ramp in m
%       v0        Initial velocity along the ramp in m/s
%
%   ENERGY is a structure containing column vectors:
%       .kinetic             Kinetic energy, J
%       .potential           Gravitational potential energy, J
%       .mechanical          Kinetic + potential energy, J
%       .frictionDissipated  Cumulative energy dissipated by friction, J
%       .accountedTotal      Mechanical + friction-dissipated energy, J
%       .balanceError        accountedTotal - initial total energy, J
%
%   The simulation ends when the box reaches the bottom of the ramp, comes
%   to rest without enough downslope force to move again, or reaches the
%   maximum simulation time.

    validateattributes(m, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, 'm', 1);
    validateattributes(mu, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'mu', 2);
    validateattributes(thetaDeg, {'numeric'}, ...
        {'real', 'finite', 'scalar', '>=', 0, '<=', 90}, ...
        mfilename, 'thetaDeg', 3);
    validateattributes(x0, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'x0', 4);
    validateattributes(v0, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'v0', 5);

    if nargin < 6 || isempty(maxTime)
        maxTime = 30.0;
    end
    validateattributes(maxTime, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, ...
        mfilename, 'maxTime', 6);

    g = 9.81;          % gravitational acceleration, m/s^2
    dt = 0.01;         % simulation time step, s
    velocityTolerance = 1.0e-10;
    positionTolerance = 1.0e-12;

    theta = deg2rad(thetaDeg);
    sinTheta = sin(theta);
    cosTheta = cos(theta);
    frictionForce = mu * m * g * cosTheta;

    maxSamples = ceil(maxTime / dt) + 2;
    time = zeros(maxSamples, 1);
    position = zeros(maxSamples, 1);
    velocity = zeros(maxSamples, 1);
    frictionDissipated = zeros(maxSamples, 1);

    position(1) = x0;
    velocity(1) = v0;
    sampleCount = 1;

    while time(sampleCount) < maxTime
        currentPosition = position(sampleCount);
        currentVelocity = velocity(sampleCount);

        % The bottom of the ramp is the end of the physical domain.
        if currentPosition <= positionTolerance && currentVelocity <= 0
            position(sampleCount) = 0;
            break
        end

        % If the box is stationary and friction can support it, it remains
        % at rest and the simulation is complete.
        if abs(currentVelocity) <= velocityTolerance && ...
                sinTheta <= mu * cosTheta + velocityTolerance
            velocity(sampleCount) = 0;
            break
        end

        stepDuration = min(dt, maxTime - time(sampleCount));
        [nextPosition, nextVelocity, elapsed, distanceMoved, hitBottom] = ...
            advanceOneStep(currentPosition, currentVelocity, stepDuration, ...
            g, mu, sinTheta, cosTheta, velocityTolerance);

        sampleCount = sampleCount + 1;
        time(sampleCount) = time(sampleCount - 1) + elapsed;
        position(sampleCount) = nextPosition;
        velocity(sampleCount) = nextVelocity;
        frictionDissipated(sampleCount) = ...
            frictionDissipated(sampleCount - 1) + ...
            frictionForce * distanceMoved;

        if hitBottom
            break
        end
    end

    time = time(1:sampleCount);
    position = position(1:sampleCount);
    velocity = velocity(1:sampleCount);
    frictionDissipated = frictionDissipated(1:sampleCount);

    kinetic = 0.5 * m .* velocity.^2;
    potential = m * g .* position * sinTheta;
    mechanical = kinetic + potential;
    accountedTotal = mechanical + frictionDissipated;
    initialTotal = accountedTotal(1);

    energy = struct();
    energy.kinetic = kinetic;
    energy.potential = potential;
    energy.mechanical = mechanical;
    energy.frictionDissipated = frictionDissipated;
    energy.accountedTotal = accountedTotal;
    energy.balanceError = accountedTotal - initialTotal;
end


function [s, v, elapsed, distanceMoved, hitBottom] = advanceOneStep( ...
        s, v, stepDuration, g, mu, sinTheta, cosTheta, velocityTolerance)
%ADVANCEONESTEP Advance the state while handling a velocity reversal.

    elapsed = 0;
    distanceMoved = 0;

    a = accelerationForState(v, g, mu, sinTheta, cosTheta, ...
        velocityTolerance);

    if abs(a) <= eps
        firstDuration = stepDuration;
        stopsDuringStep = false;
    elseif v > velocityTolerance && v + a * stepDuration < 0
        firstDuration = -v / a;
        stopsDuringStep = true;
    elseif v < -velocityTolerance && v + a * stepDuration > 0
        firstDuration = -v / a;
        stopsDuringStep = true;
    else
        firstDuration = stepDuration;
        stopsDuringStep = false;
    end

    [s, v, used, segmentDistance, hitBottom] = propagateSegment( ...
        s, v, a, firstDuration);
    elapsed = elapsed + used;
    distanceMoved = distanceMoved + segmentDistance;

    if hitBottom || ~stopsDuringStep
        return
    end

    % The first segment ended exactly when the box came to rest.
    v = 0;
    remainingTime = stepDuration - elapsed;
    if remainingTime <= eps(stepDuration)
        elapsed = stepDuration;
        return
    end

    % At rest, the box starts sliding down only when the downslope gravity
    % component exceeds the available friction force.
    if sinTheta > mu * cosTheta + velocityTolerance
        a = -g * (sinTheta - mu * cosTheta);
        [s, v, used, segmentDistance, hitBottom] = propagateSegment( ...
            s, v, a, remainingTime);
        elapsed = elapsed + used;
        distanceMoved = distanceMoved + segmentDistance;
    else
        elapsed = stepDuration;
    end
end


function a = accelerationForState(v, g, mu, sinTheta, cosTheta, ...
        velocityTolerance)
%ACCELERATIONFORSTATE Apply gravity and friction with the correct signs.

    if v > velocityTolerance
        % Moving up: both gravity and friction act down the ramp.
        a = -g * (sinTheta + mu * cosTheta);
    elseif v < -velocityTolerance
        % Moving down: friction acts up the ramp.
        a = -g * (sinTheta - mu * cosTheta);
    elseif sinTheta > mu * cosTheta + velocityTolerance
        % At rest, but friction is insufficient to prevent downward motion.
        a = -g * (sinTheta - mu * cosTheta);
    else
        % Static friction balances the downslope component of gravity.
        a = 0;
    end
end


function [sNew, vNew, usedTime, distanceMoved, hitBottom] = ...
        propagateSegment(s, v, a, duration)
%PROPAGATESEGMENT Integrate one constant-acceleration motion segment.

    candidatePosition = s + v * duration + 0.5 * a * duration^2;

    if candidatePosition >= 0
        sNew = candidatePosition;
        vNew = v + a * duration;
        usedTime = duration;
        distanceMoved = abs(sNew - s);
        hitBottom = false;
        return
    end

    % The segment crosses POSITION = 0. Find the exact crossing time so
    % the final state and energy calculation are not time-step dependent.
    usedTime = timeToBottom(s, v, a, duration);
    sNew = 0;
    vNew = v + a * usedTime;
    distanceMoved = abs(s);
    hitBottom = true;
end


function crossingTime = timeToBottom(s, v, a, maximumTime)
%TIMETOBOTTOM Solve s + v*t + 0.5*a*t^2 = 0 within the current segment.

    if abs(a) <= eps
        crossingTime = -s / v;
    else
        discriminant = max(v^2 - 2 * a * s, 0);
        rootsToCheck = [(-v + sqrt(discriminant)) / a, ...
                        (-v - sqrt(discriminant)) / a];
        validRoots = rootsToCheck(rootsToCheck >= 0 & ...
            rootsToCheck <= maximumTime + 10 * eps(maximumTime));

        if isempty(validRoots)
            % This fallback should only be reached because of roundoff.
            crossingTime = maximumTime;
        else
            crossingTime = min(validRoots);
        end
    end

    crossingTime = min(max(crossingTime, 0), maximumTime);
end
