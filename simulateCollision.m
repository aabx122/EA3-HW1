function [time, position, velocity, momentum, energy, collision] = ...
        simulateCollision(m1, m2, x1Initial, x2Initial, u1, u2, ...
        collisionType, restitution, mu, g, maxTime)
%SIMULATECOLLISION Simulate a one-dimensional collision with friction.
%
%   [TIME, POSITION, VELOCITY, MOMENTUM, ENERGY, COLLISION] =
%   SIMULATECOLLISION(M1, M2, X1INITIAL, X2INITIAL, U1, U2,
%   COLLISIONTYPE, RESTITUTION, MU, G) simulates two point objects moving
%   on a horizontal surface. Object 1 must initially be to the left of
%   object 2. Positive position and velocity point to the right.
%
%   COLLISIONTYPE may be:
%       "elastic"               Perfectly elastic collision (e = 1)
%       "perfectly inelastic"  Objects stick together (e = 0)
%       "imperfectly inelastic" Uses the supplied RESTITUTION value
%
%   RESTITUTION must be between 0 and 1. It is used only for an
%   imperfectly inelastic collision. MU defaults to 0 and G defaults to
%   9.81 m/s^2 when omitted or empty. An optional eleventh input specifies
%   the maximum simulation time; its default value is 10 seconds.
%
%   Outputs:
%       TIME      N-by-1 time array. Two entries share the collision time
%                 so plots show the instantaneous velocity change.
%       POSITION  N-by-2 array [x1, x2], m
%       VELOCITY  N-by-2 array [v1, v2], m/s
%       MOMENTUM  Structure with fields .object and .total
%       ENERGY    Structure containing kinetic energy, frictional energy
%                 dissipation, collision loss, and energy-balance error
%       COLLISION Structure containing the pre/post-impact values
%
%   The simulation uses point objects, permits one collision, and ends
%   when both objects stop or after 10 seconds.

    narginchk(7, 11)

    if nargin < 8 || isempty(restitution)
        restitution = 0.5;
    end
    if nargin < 9 || isempty(mu)
        mu = 0;
    end
    if nargin < 10 || isempty(g)
        g = 9.81;
    end
    if nargin < 11 || isempty(maxTime)
        maxTime = 10.0;
    end

    validateattributes(m1, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, 'm1', 1);
    validateattributes(m2, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, 'm2', 2);
    validateattributes(x1Initial, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'x1Initial', 3);
    validateattributes(x2Initial, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'x2Initial', 4);
    validateattributes(u1, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'u1', 5);
    validateattributes(u2, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'u2', 6);
    validateattributes(mu, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'mu', 9);
    validateattributes(g, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, 'g', 10);
    validateattributes(maxTime, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, ...
        mfilename, 'maxTime', 11);

    if x1Initial >= x2Initial
        error('simulateCollision:InvalidInitialPositions', ...
            'x1Initial must be less than x2Initial.');
    end

    [typeLabel, effectiveRestitution, objectsStick] = ...
        parseCollisionType(collisionType, restitution);

    dt = 0.001;
    velocityTolerance = 1.0e-10;
    timeTolerance = 1.0e-12;

    % One collision adds two extra samples at the impact time.
    maximumSamples = ceil(maxTime / dt) + 4;
    time = zeros(maximumSamples, 1);
    position = zeros(maximumSamples, 2);
    velocity = zeros(maximumSamples, 2);
    frictionDissipated = zeros(maximumSamples, 2);
    collisionLoss = zeros(maximumSamples, 1);

    position(1, :) = [x1Initial, x2Initial];
    velocity(1, :) = [u1, u2];
    sampleCount = 1;
    hasCollided = false;

    collision = emptyCollisionRecord(typeLabel, effectiveRestitution);

    while time(sampleCount) < maxTime - timeTolerance
        currentTime = time(sampleCount);
        currentPosition = position(sampleCount, :);
        currentVelocity = velocity(sampleCount, :);

        if all(abs(currentVelocity) <= velocityTolerance)
            velocity(sampleCount, :) = 0;
            break
        end

        stepDuration = min(dt, maxTime - currentTime);

        if hasCollided && objectsStick
            [nextX, nextV, distanceMoved] = advanceWithFriction( ...
                currentPosition(1), currentVelocity(1), stepDuration, ...
                mu, g, velocityTolerance);

            sampleCount = sampleCount + 1;
            time(sampleCount) = currentTime + stepDuration;
            position(sampleCount, :) = [nextX, nextX];
            velocity(sampleCount, :) = [nextV, nextV];
            frictionDissipated(sampleCount, :) = ...
                frictionDissipated(sampleCount - 1, :) + ...
                mu * g * distanceMoved .* [m1, m2];
            collisionLoss(sampleCount) = collisionLoss(sampleCount - 1);
            continue
        end

        [candidateX1, candidateV1, candidateDistance1] = ...
            advanceWithFriction(currentPosition(1), currentVelocity(1), ...
            stepDuration, mu, g, velocityTolerance);
        [candidateX2, candidateV2, candidateDistance2] = ...
            advanceWithFriction(currentPosition(2), currentVelocity(2), ...
            stepDuration, mu, g, velocityTolerance);

        collisionOccurs = ~hasCollided && candidateX1 >= candidateX2;

        if ~collisionOccurs
            sampleCount = sampleCount + 1;
            time(sampleCount) = currentTime + stepDuration;
            position(sampleCount, :) = [candidateX1, candidateX2];
            velocity(sampleCount, :) = [candidateV1, candidateV2];
            frictionDissipated(sampleCount, :) = ...
                frictionDissipated(sampleCount - 1, :) + ...
                mu * g .* [m1 * candidateDistance1, ...
                           m2 * candidateDistance2];
            collisionLoss(sampleCount) = collisionLoss(sampleCount - 1);
            continue
        end

        impactDelay = findImpactTime(currentPosition, currentVelocity, ...
            stepDuration, mu, g, velocityTolerance);

        [impactX1, impactU1, distanceBefore1] = advanceWithFriction( ...
            currentPosition(1), currentVelocity(1), impactDelay, ...
            mu, g, velocityTolerance);
        [impactX2, impactU2, distanceBefore2] = advanceWithFriction( ...
            currentPosition(2), currentVelocity(2), impactDelay, ...
            mu, g, velocityTolerance);

        impactPosition = 0.5 * (impactX1 + impactX2);
        impactTime = currentTime + impactDelay;
        frictionAtImpact = frictionDissipated(sampleCount, :) + ...
            mu * g .* [m1 * distanceBefore1, m2 * distanceBefore2];

        % Store the state immediately before impact.
        sampleCount = sampleCount + 1;
        time(sampleCount) = impactTime;
        position(sampleCount, :) = [impactPosition, impactPosition];
        velocity(sampleCount, :) = [impactU1, impactU2];
        frictionDissipated(sampleCount, :) = frictionAtImpact;
        collisionLoss(sampleCount) = collisionLoss(sampleCount - 1);

        [impactV1, impactV2] = postImpactVelocities( ...
            m1, m2, impactU1, impactU2, effectiveRestitution);

        kineticBefore = 0.5 * m1 * impactU1^2 + ...
            0.5 * m2 * impactU2^2;
        kineticAfter = 0.5 * m1 * impactV1^2 + ...
            0.5 * m2 * impactV2^2;
        energyLostAtImpact = max(kineticBefore - kineticAfter, 0);

        momentumBefore = m1 * impactU1 + m2 * impactU2;
        momentumAfter = m1 * impactV1 + m2 * impactV2;

        collision.occurred = true;
        collision.time = impactTime;
        collision.position = impactPosition;
        collision.velocityBefore = [impactU1, impactU2];
        collision.velocityAfter = [impactV1, impactV2];
        collision.momentumBefore = momentumBefore;
        collision.momentumAfter = momentumAfter;
        collision.momentumError = momentumAfter - momentumBefore;
        collision.kineticEnergyBefore = kineticBefore;
        collision.kineticEnergyAfter = kineticAfter;
        collision.energyLost = energyLostAtImpact;

        % Store the state immediately after impact at the same time. This
        % produces a visible vertical jump in velocity/momentum plots.
        sampleCount = sampleCount + 1;
        time(sampleCount) = impactTime;
        position(sampleCount, :) = [impactPosition, impactPosition];
        velocity(sampleCount, :) = [impactV1, impactV2];
        frictionDissipated(sampleCount, :) = frictionAtImpact;
        collisionLoss(sampleCount) = ...
            collisionLoss(sampleCount - 1) + energyLostAtImpact;

        hasCollided = true;
        remainingTime = stepDuration - impactDelay;

        if remainingTime <= timeTolerance
            continue
        end

        if objectsStick
            [nextX, nextV, distanceAfter] = advanceWithFriction( ...
                impactPosition, impactV1, remainingTime, ...
                mu, g, velocityTolerance);
            nextPosition = [nextX, nextX];
            nextVelocity = [nextV, nextV];
            distanceAfterImpact = [distanceAfter, distanceAfter];
        else
            [nextX1, nextV1, distanceAfter1] = advanceWithFriction( ...
                impactPosition, impactV1, remainingTime, ...
                mu, g, velocityTolerance);
            [nextX2, nextV2, distanceAfter2] = advanceWithFriction( ...
                impactPosition, impactV2, remainingTime, ...
                mu, g, velocityTolerance);
            nextPosition = [nextX1, nextX2];
            nextVelocity = [nextV1, nextV2];
            distanceAfterImpact = [distanceAfter1, distanceAfter2];
        end

        sampleCount = sampleCount + 1;
        time(sampleCount) = currentTime + stepDuration;
        position(sampleCount, :) = nextPosition;
        velocity(sampleCount, :) = nextVelocity;
        frictionDissipated(sampleCount, :) = ...
            frictionDissipated(sampleCount - 1, :) + ...
            mu * g .* [m1 * distanceAfterImpact(1), ...
                       m2 * distanceAfterImpact(2)];
        collisionLoss(sampleCount) = collisionLoss(sampleCount - 1);
    end

    time = time(1:sampleCount);
    position = position(1:sampleCount, :);
    velocity = velocity(1:sampleCount, :);
    frictionDissipated = frictionDissipated(1:sampleCount, :);
    collisionLoss = collisionLoss(1:sampleCount);

    momentum = struct();
    momentum.object = velocity .* [m1, m2];
    momentum.total = sum(momentum.object, 2);

    kinetic = 0.5 .* velocity.^2 .* [m1, m2];
    totalKinetic = sum(kinetic, 2);
    totalFrictionDissipated = sum(frictionDissipated, 2);
    accountedTotal = totalKinetic + totalFrictionDissipated + collisionLoss;
    initialEnergy = accountedTotal(1);

    energy = struct();
    energy.kinetic = kinetic;
    energy.totalKinetic = totalKinetic;
    energy.frictionDissipated = frictionDissipated;
    energy.totalFrictionDissipated = totalFrictionDissipated;
    energy.collisionLoss = collisionLoss;
    energy.accountedTotal = accountedTotal;
    energy.balanceError = accountedTotal - initialEnergy;
end


function [typeLabel, effectiveRestitution, objectsStick] = ...
        parseCollisionType(collisionType, restitution)
%PARSECOLLISIONTYPE Normalize the requested collision model.

    if ~(ischar(collisionType) || ...
            (isstring(collisionType) && isscalar(collisionType)))
        error('simulateCollision:InvalidCollisionType', ...
            'collisionType must be a character vector or string scalar.');
    end

    typeKey = regexprep(lower(strtrim(string(collisionType))), ...
        '[^a-z]', '');

    switch typeKey
        case {"elastic", "perfectlyelastic"}
            typeLabel = "Perfectly Elastic";
            effectiveRestitution = 1;
            objectsStick = false;

        case {"perfectlyinelastic", "plastic"}
            typeLabel = "Perfectly Inelastic";
            effectiveRestitution = 0;
            objectsStick = true;

        case {"inelastic", "imperfectlyinelastic"}
            validateattributes(restitution, {'numeric'}, ...
                {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                mfilename, 'restitution', 8);
            typeLabel = "Imperfectly Inelastic";
            effectiveRestitution = restitution;
            objectsStick = restitution == 0;

        otherwise
            error('simulateCollision:UnknownCollisionType', ...
                ['Unknown collision type. Use elastic, perfectly ', ...
                 'inelastic, or imperfectly inelastic.']);
    end
end


function collision = emptyCollisionRecord(typeLabel, restitution)
%EMPTYCOLLISIONRECORD Construct a predictable output before impact.

    collision = struct();
    collision.occurred = false;
    collision.type = typeLabel;
    collision.restitution = restitution;
    collision.time = NaN;
    collision.position = NaN;
    collision.velocityBefore = [NaN, NaN];
    collision.velocityAfter = [NaN, NaN];
    collision.momentumBefore = NaN;
    collision.momentumAfter = NaN;
    collision.momentumError = NaN;
    collision.kineticEnergyBefore = NaN;
    collision.kineticEnergyAfter = NaN;
    collision.energyLost = NaN;
end


function [v1, v2] = postImpactVelocities(m1, m2, u1, u2, restitution)
%POSTIMPACTVELOCITIES Apply momentum conservation and restitution.

    totalMass = m1 + m2;
    v1 = (m1 * u1 + m2 * u2 - m2 * restitution * (u1 - u2)) ...
        / totalMass;
    v2 = (m1 * u1 + m2 * u2 + m1 * restitution * (u1 - u2)) ...
        / totalMass;
end


function impactDelay = findImpactTime(position, velocity, maximumTime, ...
        mu, g, velocityTolerance)
%FINDIMPACTTIME Locate contact with bisection, including frictional stops.

    lowerTime = 0;
    upperTime = maximumTime;

    for iteration = 1:60
        middleTime = 0.5 * (lowerTime + upperTime);
        [x1, ~, ~] = advanceWithFriction(position(1), velocity(1), ...
            middleTime, mu, g, velocityTolerance);
        [x2, ~, ~] = advanceWithFriction(position(2), velocity(2), ...
            middleTime, mu, g, velocityTolerance);

        if x1 < x2
            lowerTime = middleTime;
        else
            upperTime = middleTime;
        end
    end

    impactDelay = upperTime;
end


function [xNew, vNew, distanceMoved] = advanceWithFriction( ...
        x, v, duration, mu, g, velocityTolerance)
%ADVANCEWITHFRICTION Integrate Coulomb friction without reversing velocity.

    if duration <= 0 || abs(v) <= velocityTolerance
        xNew = x;
        vNew = 0;
        distanceMoved = 0;
        return
    end

    acceleration = -mu * g * sign(v);

    if acceleration == 0
        xNew = x + v * duration;
        vNew = v;
        distanceMoved = abs(xNew - x);
        return
    end

    timeToStop = -v / acceleration;
    if timeToStop <= duration
        xNew = x + v * timeToStop + ...
            0.5 * acceleration * timeToStop^2;
        vNew = 0;
    else
        xNew = x + v * duration + 0.5 * acceleration * duration^2;
        vNew = v + acceleration * duration;
    end

    distanceMoved = abs(xNew - x);
end
