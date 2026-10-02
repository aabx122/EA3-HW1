classdef PhysicsTeachingApp < matlab.apps.AppBase
    %PHYSICSTEACHINGAPP Interactive ramp and collision teaching module.
    %
    % Run from the MATLAB command window with:
    %
    %   app = PhysicsTeachingApp;
    %
    % The app uses simulateRamp.m and simulateCollision.m as independent
    % physics engines. The interface is created entirely in MATLAB code so
    % it can be tested, version controlled, and packaged with MATLAB
    % Compiler without relying on generated App Designer files.

    properties (Access = public)
        UIFigure
    end

    properties (Access = private)
        ProblemTypeDropDown
        AnimationSpeedDropDown
        RampPanel
        CollisionPanel

        RampMassField
        RampFrictionField
        RampAngleField
        RampCoordinateDropDown
        RampPositionField
        RampVelocityField
        RampStopConditionDropDown
        RampStopValueLabel
        RampStopValueField

        CollisionMass1Field
        CollisionMass2Field
        CollisionPosition1Field
        CollisionPosition2Field
        CollisionVelocity1Field
        CollisionVelocity2Field
        CollisionTypeDropDown
        RestitutionField
        CollisionFrictionField
        GravityField
        CollisionStopConditionDropDown
        CollisionStopValueLabel
        CollisionStopValueField

        RunButton
        StopButton
        ResetButton
        AnimationAxes
        OutputTabs
        PositionTab
        SpeedTab
        MomentumTab
        EnergyTab
        PositionAxes
        SpeedAxes
        MomentumAxes
        EnergyAxes
        StatusLamp
        StatusLabel
        ResultsTextArea

        StopRequested = false
    end

    methods (Access = private)
        function startup(app)
            app.updatePanelVisibility();
            app.updateRestitutionField();
            app.updateFinalConditionFields();
            app.clearOutput();
            app.setStatus('Ready - choose a problem and enter parameters.', ...
                [0.20 0.62 0.34]);
        end

        function problemTypeChanged(app)
            app.updatePanelVisibility();
            app.clearOutput();
            app.setStatus('Ready - parameters updated for the selected problem.', ...
                [0.20 0.62 0.34]);
        end

        function updatePanelVisibility(app)
            isRamp = strcmp(app.ProblemTypeDropDown.Value, ...
                'Sliding Box on Ramp');
            app.RampPanel.Visible = app.onOff(isRamp);
            app.CollisionPanel.Visible = app.onOff(~isRamp);
        end

        function collisionTypeChanged(app)
            app.updateRestitutionField();
        end

        function finalConditionChanged(app)
            app.updateFinalConditionFields();
        end

        function updateFinalConditionFields(app)
            rampCondition = app.RampStopConditionDropDown.Value;
            switch rampCondition
                case 'Maximum Time'
                    app.RampStopValueLabel.Text = 'Maximum time (s)';
                    rampNeedsValue = true;
                case 'Position Reached'
                    app.RampStopValueLabel.Text = 'Target position (m)';
                    rampNeedsValue = true;
                case 'Speed Reached'
                    app.RampStopValueLabel.Text = 'Target speed (m/s)';
                    rampNeedsValue = true;
                otherwise
                    app.RampStopValueLabel.Text = 'Target value';
                    rampNeedsValue = false;
            end
            app.RampStopValueField.Enable = app.onOff(rampNeedsValue);

            collisionCondition = app.CollisionStopConditionDropDown.Value;
            switch collisionCondition
                case 'Maximum Time'
                    app.CollisionStopValueLabel.Text = 'Maximum time (s)';
                    collisionNeedsValue = true;
                case {'Object 1 Position', 'Object 2 Position'}
                    app.CollisionStopValueLabel.Text = 'Target position (m)';
                    collisionNeedsValue = true;
                case {'Object 1 Speed', 'Object 2 Speed'}
                    app.CollisionStopValueLabel.Text = 'Target speed (m/s)';
                    collisionNeedsValue = true;
                otherwise
                    app.CollisionStopValueLabel.Text = 'Target value';
                    collisionNeedsValue = false;
            end
            app.CollisionStopValueField.Enable = ...
                app.onOff(collisionNeedsValue);
        end

        function updateRestitutionField(app)
            useRestitution = strcmp(app.CollisionTypeDropDown.Value, ...
                'Imperfectly Inelastic');
            app.RestitutionField.Enable = app.onOff(useRestitution);
        end

        function runSimulation(app)
            app.StopRequested = false;
            app.RunButton.Enable = 'off';
            app.StopButton.Enable = 'on';
            cleanup = onCleanup(@() app.finishRun());
            app.setStatus('Calculating simulation...', [0.20 0.48 0.85]);
            drawnow

            try
                if strcmp(app.ProblemTypeDropDown.Value, ...
                        'Sliding Box on Ramp')
                    app.runRampSimulation();
                else
                    app.runCollisionSimulation();
                end
            catch errorDetails
                app.setStatus('Simulation error - check the input values.', ...
                    [0.86 0.25 0.22]);
                uialert(app.UIFigure, errorDetails.message, ...
                    'Simulation Error', 'Icon', 'error');
            end

            clear cleanup
        end

        function finishRun(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return
            end
            app.RunButton.Enable = 'on';
            app.StopButton.Enable = 'off';
        end

        function requestStop(app)
            app.StopRequested = true;
            app.setStatus('Stopping animation...', [0.92 0.58 0.16]);
        end

        function resetInputs(app)
            app.StopRequested = true;

            app.RampMassField.Value = 1.0;
            app.RampFrictionField.Value = 0.4;
            app.RampAngleField.Value = 25.0;
            app.RampCoordinateDropDown.Value = 'Along ramp';
            app.RampPositionField.Value = 3.0;
            app.RampVelocityField.Value = 0.0;
            app.RampStopConditionDropDown.Value = 'Natural End';
            app.RampStopValueField.Value = 5.0;

            app.CollisionMass1Field.Value = 3.0;
            app.CollisionMass2Field.Value = 1.0;
            app.CollisionPosition1Field.Value = 0.0;
            app.CollisionPosition2Field.Value = 1.0;
            app.CollisionVelocity1Field.Value = 2.0;
            app.CollisionVelocity2Field.Value = 1.0;
            app.CollisionTypeDropDown.Value = 'Perfectly Elastic';
            app.RestitutionField.Value = 0.5;
            app.CollisionFrictionField.Value = 0.0;
            app.GravityField.Value = 9.81;
            app.CollisionStopConditionDropDown.Value = 'Maximum Time';
            app.CollisionStopValueField.Value = 10.0;

            app.updateRestitutionField();
            app.updateFinalConditionFields();
            app.clearOutput();
            app.setStatus('Inputs reset to the verification examples.', ...
                [0.20 0.62 0.34]);
        end

        function runRampSimulation(app)
            mass = app.RampMassField.Value;
            friction = app.RampFrictionField.Value;
            angleDeg = app.RampAngleField.Value;
            initialPosition = app.RampPositionField.Value;
            initialVelocity = app.RampVelocityField.Value;
            stopCondition = app.RampStopConditionDropDown.Value;
            stopValue = app.RampStopValueField.Value;

            if strcmp(stopCondition, 'Maximum Time') && stopValue <= 0
                error('PhysicsTeachingApp:InvalidStopValue', ...
                    'Maximum time must be greater than zero.');
            end
            if strcmp(stopCondition, 'Speed Reached') && stopValue < 0
                error('PhysicsTeachingApp:InvalidStopValue', ...
                    'Target speed cannot be negative.');
            end

            if strcmp(app.RampCoordinateDropDown.Value, 'Horizontal')
                cosineAngle = cosd(angleDeg);
                if cosineAngle <= 1.0e-8
                    error('PhysicsTeachingApp:InvalidCoordinate', ...
                        ['Horizontal coordinates are undefined for a ', ...
                         '90-degree ramp.']);
                end
                positionAlongRamp = initialPosition / cosineAngle;
                velocityAlongRamp = initialVelocity / cosineAngle;
                positionScale = cosineAngle;
                coordinateLabel = 'Horizontal position (m)';
                speedLabel = 'Horizontal speed (m/s)';
            else
                positionAlongRamp = initialPosition;
                velocityAlongRamp = initialVelocity;
                positionScale = 1;
                coordinateLabel = 'Position along ramp (m)';
                speedLabel = 'Speed along ramp (m/s)';
            end

            if strcmp(stopCondition, 'Maximum Time')
                simulationLimit = stopValue;
            else
                simulationLimit = 30.0;
            end

            [time, position, velocity, energy] = simulateRamp( ...
                mass, friction, angleDeg, positionAlongRamp, ...
                velocityAlongRamp, simulationLimit);

            [time, position, velocity, energy, conditionReached] = ...
                app.applyRampFinalCondition(time, position, velocity, ...
                energy, positionScale, stopCondition, stopValue);

            displayPosition = position .* positionScale;
            displaySpeed = abs(velocity) .* positionScale;

            app.plotRampResults(time, displayPosition, displaySpeed, ...
                energy, coordinateLabel, speedLabel);
            app.updateRampSummary(time, displayPosition, displaySpeed, ...
                velocity .* positionScale, energy, stopCondition, stopValue, ...
                conditionReached);

            app.setStatus('Results calculated - playing ramp animation...', ...
                [0.20 0.48 0.85]);
            app.animateRamp(time, position, angleDeg);

            if app.StopRequested
                app.setStatus('Animation stopped; calculated results remain available.', ...
                    [0.92 0.58 0.16]);
            else
                app.setStatus('Ramp simulation complete.', [0.20 0.62 0.34]);
            end
        end

        function runCollisionSimulation(app)
            collisionType = lower(app.CollisionTypeDropDown.Value);
            stopCondition = app.CollisionStopConditionDropDown.Value;
            stopValue = app.CollisionStopValueField.Value;

            if strcmp(stopCondition, 'Maximum Time') && stopValue <= 0
                error('PhysicsTeachingApp:InvalidStopValue', ...
                    'Maximum time must be greater than zero.');
            end
            if contains(stopCondition, 'Speed') && stopValue < 0
                error('PhysicsTeachingApp:InvalidStopValue', ...
                    'Target speed cannot be negative.');
            end

            if strcmp(stopCondition, 'Maximum Time')
                simulationLimit = stopValue;
            else
                simulationLimit = 10.0;
            end

            [time, position, velocity, momentum, energy, collision] = ...
                simulateCollision( ...
                app.CollisionMass1Field.Value, ...
                app.CollisionMass2Field.Value, ...
                app.CollisionPosition1Field.Value, ...
                app.CollisionPosition2Field.Value, ...
                app.CollisionVelocity1Field.Value, ...
                app.CollisionVelocity2Field.Value, ...
                collisionType, app.RestitutionField.Value, ...
                app.CollisionFrictionField.Value, app.GravityField.Value, ...
                simulationLimit);

            [time, position, velocity, momentum, energy, collision, ...
                conditionReached] = app.applyCollisionFinalCondition( ...
                time, position, velocity, momentum, energy, collision, ...
                stopCondition, stopValue);

            app.plotCollisionResults(time, position, velocity, momentum, ...
                energy, collision);
            app.updateCollisionSummary(time, position, velocity, ...
                energy, collision, stopCondition, stopValue, ...
                conditionReached);

            app.setStatus('Results calculated - playing collision animation...', ...
                [0.20 0.48 0.85]);
            app.animateCollision(time, position, collision);

            if app.StopRequested
                app.setStatus('Animation stopped; calculated results remain available.', ...
                    [0.92 0.58 0.16]);
            elseif collision.occurred
                app.setStatus('Collision simulation complete.', ...
                    [0.20 0.62 0.34]);
            else
                app.setStatus('Simulation complete - no collision occurred.', ...
                    [0.92 0.58 0.16]);
            end
        end

        function plotRampResults(app, time, position, speed, energy, ...
                positionLabel, speedLabel)
            app.OutputTabs.SelectedTab = app.PositionTab;

            cla(app.PositionAxes)
            plot(app.PositionAxes, time, position, 'LineWidth', 1.8, ...
                'Color', [0.12 0.42 0.78]);
            app.formatAxes(app.PositionAxes, 'Position vs Time', ...
                'Time (s)', positionLabel);

            cla(app.SpeedAxes)
            plot(app.SpeedAxes, time, speed, 'LineWidth', 1.8, ...
                'Color', [0.88 0.36 0.18]);
            app.formatAxes(app.SpeedAxes, 'Speed vs Time', ...
                'Time (s)', speedLabel);

            cla(app.MomentumAxes)
            axis(app.MomentumAxes, 'off')
            text(app.MomentumAxes, 0.5, 0.55, ...
                {'Momentum is not required for the ramp model.', ...
                 'Open the Energy tab to inspect conservation.'}, ...
                'HorizontalAlignment', 'center', 'FontSize', 15, ...
                'Color', [0.32 0.37 0.45]);

            cla(app.EnergyAxes)
            hold(app.EnergyAxes, 'on')
            plot(app.EnergyAxes, time, energy.kinetic, 'LineWidth', 1.6)
            plot(app.EnergyAxes, time, energy.potential, 'LineWidth', 1.6)
            plot(app.EnergyAxes, time, energy.frictionDissipated, ...
                'LineWidth', 1.6)
            plot(app.EnergyAxes, time, energy.accountedTotal, 'k--', ...
                'LineWidth', 1.8)
            hold(app.EnergyAxes, 'off')
            app.formatAxes(app.EnergyAxes, ...
                'Energy Transformation and Conservation', ...
                'Time (s)', 'Energy (J)');
            legend(app.EnergyAxes, {'Kinetic', 'Potential', ...
                'Friction dissipated', 'Mechanical + dissipated'}, ...
                'Location', 'best');
        end

        function plotCollisionResults(app, time, position, velocity, ...
                momentum, energy, collision)
            app.OutputTabs.SelectedTab = app.PositionTab;

            cla(app.PositionAxes)
            hold(app.PositionAxes, 'on')
            positionLine1 = plot(app.PositionAxes, time, position(:, 1), ...
                'LineWidth', 1.7);
            positionLine2 = plot(app.PositionAxes, time, position(:, 2), ...
                'LineWidth', 1.7);
            if collision.occurred
                xline(app.PositionAxes, collision.time, 'k--', ...
                    'Collision', 'LineWidth', 1.2);
            end
            hold(app.PositionAxes, 'off')
            app.formatAxes(app.PositionAxes, 'Position vs Time', ...
                'Time (s)', 'Position (m)');
            legend(app.PositionAxes, [positionLine1, positionLine2], ...
                {'Object 1', 'Object 2'}, 'Location', 'best');

            cla(app.SpeedAxes)
            hold(app.SpeedAxes, 'on')
            speedLine1 = plot(app.SpeedAxes, time, abs(velocity(:, 1)), ...
                'LineWidth', 1.7);
            speedLine2 = plot(app.SpeedAxes, time, abs(velocity(:, 2)), ...
                'LineWidth', 1.7);
            if collision.occurred
                xline(app.SpeedAxes, collision.time, 'k--', ...
                    'Collision', 'LineWidth', 1.2);
            end
            hold(app.SpeedAxes, 'off')
            app.formatAxes(app.SpeedAxes, 'Speed vs Time', ...
                'Time (s)', 'Speed (m/s)');
            legend(app.SpeedAxes, [speedLine1, speedLine2], ...
                {'Object 1', 'Object 2'}, 'Location', 'best');

            cla(app.MomentumAxes)
            axis(app.MomentumAxes, 'on')
            hold(app.MomentumAxes, 'on')
            momentumLine1 = plot(app.MomentumAxes, time, ...
                momentum.object(:, 1), 'LineWidth', 1.6);
            momentumLine2 = plot(app.MomentumAxes, time, ...
                momentum.object(:, 2), 'LineWidth', 1.6);
            totalMomentumLine = plot(app.MomentumAxes, time, ...
                momentum.total, 'k--', 'LineWidth', 1.8);
            if collision.occurred
                xline(app.MomentumAxes, collision.time, 'k:', ...
                    'Collision', 'LineWidth', 1.2);
            end
            hold(app.MomentumAxes, 'off')
            app.formatAxes(app.MomentumAxes, 'Momentum vs Time', ...
                'Time (s)', 'Momentum (kg*m/s)');
            legend(app.MomentumAxes, ...
                [momentumLine1, momentumLine2, totalMomentumLine], ...
                {'Object 1', 'Object 2', 'Total'}, 'Location', 'best');

            cla(app.EnergyAxes)
            hold(app.EnergyAxes, 'on')
            kineticLine = plot(app.EnergyAxes, time, ...
                energy.totalKinetic, 'LineWidth', 1.6);
            frictionLine = plot(app.EnergyAxes, time, ...
                energy.totalFrictionDissipated, 'LineWidth', 1.6);
            lossLine = plot(app.EnergyAxes, time, ...
                energy.collisionLoss, 'LineWidth', 1.6);
            totalLine = plot(app.EnergyAxes, time, ...
                energy.accountedTotal, 'k--', 'LineWidth', 1.8);
            if collision.occurred
                xline(app.EnergyAxes, collision.time, 'k:', ...
                    'Collision', 'LineWidth', 1.2);
            end
            hold(app.EnergyAxes, 'off')
            app.formatAxes(app.EnergyAxes, 'Energy Transformation', ...
                'Time (s)', 'Energy (J)');
            legend(app.EnergyAxes, ...
                [kineticLine, frictionLine, lossLine, totalLine], ...
                {'Total kinetic', 'Friction dissipated', ...
                 'Collision loss', 'Accounted total'}, ...
                'Location', 'best');
        end

        function updateRampSummary(app, time, position, speed, ...
                signedVelocity, energy, stopCondition, stopValue, ...
                conditionReached)
            maximumError = max(abs(energy.balanceError));
            if ~conditionReached && ~strcmp(stopCondition, 'Natural End')
                outcome = sprintf('Requested final condition was not reached: %s.', ...
                    stopCondition);
            elseif strcmp(stopCondition, 'Maximum Time')
                outcome = sprintf('Stopped at the maximum time of %.4f s.', ...
                    stopValue);
            elseif strcmp(stopCondition, 'Position Reached')
                outcome = sprintf('Stopped when position reached %.4f m.', ...
                    stopValue);
            elseif strcmp(stopCondition, 'Speed Reached')
                outcome = sprintf('Stopped when speed reached %.4f m/s.', ...
                    stopValue);
            elseif strcmp(stopCondition, 'Object Stops')
                outcome = 'Stopped at the first rest point.';
            elseif isscalar(time)
                outcome = 'The box remains at rest.';
            elseif position(end) == 0
                outcome = 'The box reached the bottom of the ramp.';
            else
                outcome = 'The maximum simulation time was reached.';
            end

            app.ResultsTextArea.Value = {
                outcome
                sprintf('Initial: position = %.4f m, speed = %.4f m/s', ...
                    position(1), speed(1))
                sprintf('Final:   position = %.4f m, velocity = %.4f m/s', ...
                    position(end), signedVelocity(end))
                sprintf(['Energy check: mechanical + friction = %.6f J; ', ...
                    'maximum error = %.3e J'], ...
                    energy.accountedTotal(end), maximumError)
                };
        end

        function updateCollisionSummary(app, time, position, velocity, ...
                energy, collision, stopCondition, stopValue, conditionReached)
            maximumError = max(abs(energy.balanceError));
            if collision.occurred
                firstLine = sprintf('%s collision at t = %.4f s, x = %.4f m.', ...
                    collision.type, collision.time, collision.position);
                secondLine = sprintf(['Before: v_1 = %.4f, v_2 = %.4f m/s; ', ...
                    'after: v_1 = %.4f, v_2 = %.4f m/s'], ...
                    collision.velocityBefore(1), collision.velocityBefore(2), ...
                    collision.velocityAfter(1), collision.velocityAfter(2));
                thirdLine = sprintf(['Momentum error = %.3e kg*m/s; ', ...
                    'collision energy loss = %.6f J'], ...
                    collision.momentumError, collision.energyLost);
            else
                firstLine = 'No collision occurred during the simulation.';
                secondLine = sprintf(['Final positions: x_1 = %.4f m, ', ...
                    'x_2 = %.4f m'], position(end, 1), position(end, 2));
                thirdLine = sprintf(['Final velocities: v_1 = %.4f m/s, ', ...
                    'v_2 = %.4f m/s'], velocity(end, 1), velocity(end, 2));
            end

            if ~conditionReached
                stopLine = sprintf('Final condition not reached: %s.', ...
                    stopCondition);
            elseif strcmp(stopCondition, 'Both Objects Stop')
                stopLine = 'Final condition: both objects stopped.';
            else
                stopLine = sprintf('Final condition: %s = %.4f.', ...
                    stopCondition, stopValue);
            end

            app.ResultsTextArea.Value = {
                stopLine
                firstLine
                secondLine
                thirdLine
                sprintf(['Energy accounting at t = %.3f s: %.6f J; ', ...
                    'maximum error = %.3e J'], ...
                    time(end), energy.accountedTotal(end), maximumError)
                };
        end

        function [time, position, velocity, energy, conditionReached] = ...
                applyRampFinalCondition(app, time, position, velocity, ...
                energy, positionScale, stopCondition, stopValue)
            conditionReached = true;
            eventIndex = [];
            interpolationFraction = 1;

            switch stopCondition
                case 'Natural End'
                    return

                case 'Maximum Time'
                    tolerance = 1.0e-9 * max(1, abs(stopValue));
                    conditionReached = time(end) >= stopValue - tolerance;
                    return

                case 'Position Reached'
                    displayedPosition = position .* positionScale;
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(displayedPosition, stopValue);

                case 'Speed Reached'
                    displayedSpeed = abs(velocity) .* positionScale;
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(displayedSpeed, stopValue);

                case 'Object Stops'
                    [eventIndex, interpolationFraction] = ...
                        app.firstObjectStop(velocity);
            end

            conditionReached = ~isempty(eventIndex);
            if conditionReached
                originalSampleCount = numel(time);
                time = app.truncateArray(time, eventIndex, ...
                    interpolationFraction);
                position = app.truncateArray(position, eventIndex, ...
                    interpolationFraction);
                velocity = app.truncateArray(velocity, eventIndex, ...
                    interpolationFraction);
                energy = app.truncateStructure(energy, originalSampleCount, ...
                    eventIndex, interpolationFraction);

                if strcmp(stopCondition, 'Object Stops')
                    velocity(end) = 0;
                end
            end
        end

        function [time, position, velocity, momentum, energy, collision, ...
                conditionReached] = applyCollisionFinalCondition(app, ...
                time, position, velocity, momentum, energy, collision, ...
                stopCondition, stopValue)
            eventIndex = [];
            interpolationFraction = 1;

            switch stopCondition
                case 'Maximum Time'
                    tolerance = 1.0e-9 * max(1, abs(stopValue));
                    conditionReached = time(end) >= stopValue - tolerance;
                    return

                case 'Object 1 Position'
                    series = position(:, 1);
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(series, stopValue);

                case 'Object 2 Position'
                    series = position(:, 2);
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(series, stopValue);

                case 'Object 1 Speed'
                    series = abs(velocity(:, 1));
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(series, stopValue);

                case 'Object 2 Speed'
                    series = abs(velocity(:, 2));
                    [eventIndex, interpolationFraction] = ...
                        app.firstCrossing(series, stopValue);

                case 'Both Objects Stop'
                    [eventIndex, interpolationFraction] = ...
                        app.firstBothObjectsStop(velocity);
            end

            conditionReached = ~isempty(eventIndex);
            if ~conditionReached
                return
            end

            originalSampleCount = numel(time);
            time = app.truncateArray(time, eventIndex, ...
                interpolationFraction);
            position = app.truncateArray(position, eventIndex, ...
                interpolationFraction);
            velocity = app.truncateArray(velocity, eventIndex, ...
                interpolationFraction);
            momentum = app.truncateStructure(momentum, originalSampleCount, ...
                eventIndex, interpolationFraction);
            energy = app.truncateStructure(energy, originalSampleCount, ...
                eventIndex, interpolationFraction);

            if strcmp(stopCondition, 'Both Objects Stop')
                velocity(end, :) = 0;
                momentum.object(end, :) = 0;
                momentum.total(end) = 0;
            end

            if collision.occurred && time(end) < collision.time - 1.0e-10
                collision.occurred = false;
            end
        end

        function [eventIndex, interpolationFraction] = ...
                firstCrossing(app, series, target) %#ok<INUSD>
            eventIndex = [];
            interpolationFraction = 1;
            tolerance = 1.0e-10 * max([1; abs(series(:)); abs(target)]);

            if abs(series(1) - target) <= tolerance
                eventIndex = 1;
                return
            end

            for index = 2:numel(series)
                previousDifference = series(index - 1) - target;
                currentDifference = series(index) - target;

                if abs(currentDifference) <= tolerance
                    eventIndex = index;
                    interpolationFraction = 1;
                    return
                end

                if previousDifference * currentDifference < 0
                    eventIndex = index;
                    interpolationFraction = (target - series(index - 1)) / ...
                        (series(index) - series(index - 1));
                    interpolationFraction = min(max( ...
                        interpolationFraction, 0), 1);
                    return
                end
            end
        end

        function [eventIndex, interpolationFraction] = ...
                firstObjectStop(app, velocity) %#ok<INUSD>
            eventIndex = [];
            interpolationFraction = 1;
            tolerance = 1.0e-9;

            if isscalar(velocity) && abs(velocity(1)) <= tolerance
                eventIndex = 1;
                return
            end

            hasMoved = abs(velocity(1)) > tolerance;
            for index = 2:numel(velocity)
                if hasMoved && abs(velocity(index)) <= tolerance
                    eventIndex = index;
                    interpolationFraction = 1;
                    return
                end
                if hasMoved && velocity(index - 1) * velocity(index) < 0
                    eventIndex = index;
                    interpolationFraction = abs(velocity(index - 1)) / ...
                        (abs(velocity(index - 1)) + abs(velocity(index)));
                    return
                end
                hasMoved = hasMoved || abs(velocity(index)) > tolerance;
            end
        end

        function [eventIndex, interpolationFraction] = ...
                firstBothObjectsStop(app, velocity) %#ok<INUSD>
            eventIndex = [];
            interpolationFraction = 1;
            tolerance = 1.0e-9;
            stopped = all(abs(velocity) <= tolerance, 2);

            if stopped(1)
                eventIndex = 1;
                return
            end

            firstStop = find(stopped, 1, 'first');
            if ~isempty(firstStop)
                eventIndex = firstStop;
            end
        end

        function truncated = truncateArray(app, values, eventIndex, ...
                interpolationFraction) %#ok<INUSD>
            if eventIndex == 1
                truncated = values(1, :);
                return
            end

            interpolatedValue = values(eventIndex - 1, :) + ...
                interpolationFraction .* ...
                (values(eventIndex, :) - values(eventIndex - 1, :));
            truncated = [values(1:eventIndex - 1, :); interpolatedValue];
        end

        function output = truncateStructure(app, input, originalSampleCount, ...
                eventIndex, interpolationFraction)
            output = input;
            fieldList = fieldnames(input);
            for fieldIndex = 1:numel(fieldList)
                fieldName = fieldList{fieldIndex};
                values = input.(fieldName);
                if isnumeric(values) && size(values, 1) == originalSampleCount
                    output.(fieldName) = app.truncateArray(values, ...
                        eventIndex, interpolationFraction);
                end
            end
        end

        function animateRamp(app, time, position, angleDeg)
            cla(app.AnimationAxes)
            hold(app.AnimationAxes, 'on')

            maximumPosition = max([position; 1]);
            rampX = [0, 1.08 * maximumPosition * cosd(angleDeg)];
            rampY = [0, 1.08 * maximumPosition * sind(angleDeg)];
            plot(app.AnimationAxes, rampX, rampY, 'Color', ...
                [0.27 0.31 0.38], 'LineWidth', 5)
            boxMarker = plot(app.AnimationAxes, ...
                position(1) * cosd(angleDeg), ...
                position(1) * sind(angleDeg), 's', ...
                'MarkerSize', 16, 'MarkerFaceColor', [0.16 0.55 0.78], ...
                'MarkerEdgeColor', [0.08 0.25 0.38], 'LineWidth', 1.5);
            hold(app.AnimationAxes, 'off')
            axis(app.AnimationAxes, 'equal')
            grid(app.AnimationAxes, 'on')
            xlim(app.AnimationAxes, [-0.08 * maximumPosition, ...
                max(rampX(2) * 1.08, 0.5)])
            ylim(app.AnimationAxes, [-0.08 * maximumPosition, ...
                max(rampY(2) * 1.12, 0.5)])
            xlabel(app.AnimationAxes, 'Horizontal distance (m)')
            ylabel(app.AnimationAxes, 'Height (m)')

            indices = app.animationIndices(numel(time));
            for index = indices
                if app.StopRequested
                    break
                end
                boxMarker.XData = position(index) * cosd(angleDeg);
                boxMarker.YData = position(index) * sind(angleDeg);
                title(app.AnimationAxes, sprintf( ...
                    'Sliding Ramp Animation - t = %.2f s', time(index)))
                drawnow limitrate
                app.animationPause();
            end
        end

        function animateCollision(app, time, position, collision)
            cla(app.AnimationAxes)
            hold(app.AnimationAxes, 'on')

            minimumX = min(position, [], 'all');
            maximumX = max(position, [], 'all');
            span = max(maximumX - minimumX, 1);
            plot(app.AnimationAxes, ...
                [minimumX - 0.08 * span, maximumX + 0.08 * span], ...
                [0, 0], 'Color', [0.27 0.31 0.38], 'LineWidth', 4)
            object1 = plot(app.AnimationAxes, position(1, 1), 0, 's', ...
                'MarkerSize', 16, 'MarkerFaceColor', [0.16 0.55 0.78], ...
                'MarkerEdgeColor', [0.08 0.25 0.38], 'LineWidth', 1.5);
            object2 = plot(app.AnimationAxes, position(1, 2), 0, 'o', ...
                'MarkerSize', 16, 'MarkerFaceColor', [0.94 0.46 0.20], ...
                'MarkerEdgeColor', [0.52 0.20 0.07], 'LineWidth', 1.5);
            hold(app.AnimationAxes, 'off')
            grid(app.AnimationAxes, 'on')
            xlim(app.AnimationAxes, ...
                [minimumX - 0.1 * span, maximumX + 0.1 * span])
            ylim(app.AnimationAxes, [-0.7, 0.7])
            yticks(app.AnimationAxes, [])
            xlabel(app.AnimationAxes, 'Position (m)')

            indices = app.animationIndices(numel(time));
            for index = indices
                if app.StopRequested
                    break
                end
                object1.XData = position(index, 1);
                object2.XData = position(index, 2);
                if collision.occurred && time(index) >= collision.time
                    phase = 'after impact';
                else
                    phase = 'before impact';
                end
                title(app.AnimationAxes, sprintf( ...
                    'Collision Animation - t = %.2f s (%s)', ...
                    time(index), phase))
                drawnow limitrate
                app.animationPause();
            end
        end

        function indices = animationIndices(app, sampleCount)
            if strcmp(app.AnimationSpeedDropDown.Value, 'Instant')
                indices = sampleCount;
            else
                frameCount = min(sampleCount, 180);
                indices = unique(round(linspace(1, sampleCount, frameCount)));
            end
        end

        function animationPause(app)
            switch app.AnimationSpeedDropDown.Value
                case '0.5x'
                    pause(0.030)
                case '1x'
                    pause(0.015)
                case '2x'
                    pause(0.006)
                otherwise
                    % Instant mode displays only the final frame.
            end
        end

        function clearOutput(app)
            axesList = {app.AnimationAxes, app.PositionAxes, app.SpeedAxes, ...
                app.MomentumAxes, app.EnergyAxes};
            for index = 1:numel(axesList)
                cla(axesList{index})
                axis(axesList{index}, 'on')
                grid(axesList{index}, 'on')
            end

            title(app.AnimationAxes, 'Simulation Preview')
            xlabel(app.AnimationAxes, 'Position')
            ylabel(app.AnimationAxes, '')
            title(app.PositionAxes, 'Position vs Time')
            title(app.SpeedAxes, 'Speed vs Time')
            title(app.MomentumAxes, 'Momentum vs Time')
            title(app.EnergyAxes, 'Energy vs Time')
            app.ResultsTextArea.Value = { ...
                'Run a simulation to view numerical initial/final conditions,', ...
                'conservation checks, animation, and time-history plots.'};
        end

        function formatAxes(app, targetAxes, titleText, xLabelText, ...
                yLabelText) %#ok<INUSD>
            grid(targetAxes, 'on')
            box(targetAxes, 'on')
            title(targetAxes, titleText)
            xlabel(targetAxes, xLabelText)
            ylabel(targetAxes, yLabelText)
            targetAxes.FontSize = 12;
            targetAxes.LineWidth = 1;
        end

        function setStatus(app, message, color)
            app.StatusLabel.Text = message;
            app.StatusLamp.Color = color;
        end

        function value = onOff(app, condition) %#ok<INUSD>
            if condition
                value = 'on';
            else
                value = 'off';
            end
        end

        function field = addNumericInput(app, parentGrid, row, labelText, ...
                defaultValue, limits) %#ok<INUSD>
            label = uilabel(parentGrid, 'Text', labelText, ...
                'FontColor', [0.24 0.28 0.34]);
            label.Layout.Row = row;
            label.Layout.Column = 1;
            field = uieditfield(parentGrid, 'numeric', ...
                'Value', defaultValue, 'Limits', limits);
            field.Layout.Row = row;
            field.Layout.Column = 2;
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Name = 'Mechanics Learning Lab';
            app.UIFigure.Position = [80 60 1420 880];
            app.UIFigure.Color = [0.95 0.96 0.98];

            rootGrid = uigridlayout(app.UIFigure, [3 1]);
            rootGrid.RowHeight = {74, '1x', 118};
            rootGrid.Padding = [14 12 14 12];
            rootGrid.RowSpacing = 10;

            headerGrid = uigridlayout(rootGrid, [2 2]);
            headerGrid.Layout.Row = 1;
            headerGrid.BackgroundColor = [0.10 0.16 0.25];
            headerGrid.RowHeight = {36, 24};
            headerGrid.ColumnWidth = {'1x', 220};
            headerGrid.Padding = [18 6 18 6];

            titleLabel = uilabel(headerGrid, 'Text', 'Mechanics Learning Lab', ...
                'FontSize', 24, 'FontWeight', 'bold', ...
                'FontColor', [1 1 1]);
            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = 1;
            subtitleLabel = uilabel(headerGrid, ...
                'Text', 'Explore motion, momentum, and energy through simulation', ...
                'FontSize', 13, 'FontColor', [0.72 0.82 0.94]);
            subtitleLabel.Layout.Row = 2;
            subtitleLabel.Layout.Column = 1;
            modeLabel = uilabel(headerGrid, ...
                'Text', 'Interactive teaching module', ...
                'HorizontalAlignment', 'right', 'FontSize', 12, ...
                'FontColor', [0.72 0.82 0.94]);
            modeLabel.Layout.Row = [1 2];
            modeLabel.Layout.Column = 2;

            mainGrid = uigridlayout(rootGrid, [1 2]);
            mainGrid.Layout.Row = 2;
            mainGrid.ColumnWidth = {385, '1x'};
            mainGrid.ColumnSpacing = 12;
            mainGrid.Padding = [0 0 0 0];

            inputPanel = uipanel(mainGrid, 'Title', 'Simulation Controls', ...
                'FontWeight', 'bold', 'FontSize', 14, ...
                'BackgroundColor', [1 1 1]);
            inputPanel.Layout.Column = 1;
            inputGrid = uigridlayout(inputPanel, [6 1]);
            inputGrid.RowHeight = {24, 34, 24, 34, '1x', 46};
            inputGrid.Padding = [12 10 12 12];
            inputGrid.RowSpacing = 7;

            problemLabel = uilabel(inputGrid, 'Text', 'Problem type', ...
                'FontWeight', 'bold');
            problemLabel.Layout.Row = 1;
            app.ProblemTypeDropDown = uidropdown(inputGrid, ...
                'Items', {'Sliding Box on Ramp', '1-D Collision'}, ...
                'Value', 'Sliding Box on Ramp', ...
                'ValueChangedFcn', @(~, ~) app.problemTypeChanged());
            app.ProblemTypeDropDown.Layout.Row = 2;

            speedLabel = uilabel(inputGrid, 'Text', 'Animation speed', ...
                'FontWeight', 'bold');
            speedLabel.Layout.Row = 3;
            app.AnimationSpeedDropDown = uidropdown(inputGrid, ...
                'Items', {'0.5x', '1x', '2x', 'Instant'}, 'Value', '1x');
            app.AnimationSpeedDropDown.Layout.Row = 4;

            app.RampPanel = uipanel(inputGrid, 'Title', 'Ramp Parameters', ...
                'FontWeight', 'bold', 'BackgroundColor', [0.97 0.98 1]);
            app.RampPanel.Layout.Row = 5;
            rampGrid = uigridlayout(app.RampPanel, [8 2]);
            rampGrid.RowHeight = repmat({34}, 1, 8);
            rampGrid.ColumnWidth = {'1x', 155};
            rampGrid.Padding = [10 8 10 8];

            app.RampMassField = app.addNumericInput(rampGrid, 1, ...
                'Mass (kg)', 1.0, [eps Inf]);
            app.RampFrictionField = app.addNumericInput(rampGrid, 2, ...
                'Friction coefficient', 0.4, [0 Inf]);
            app.RampAngleField = app.addNumericInput(rampGrid, 3, ...
                'Ramp angle (deg)', 25.0, [0 90]);
            coordinateLabel = uilabel(rampGrid, 'Text', 'Input coordinate', ...
                'FontColor', [0.24 0.28 0.34]);
            coordinateLabel.Layout.Row = 4;
            coordinateLabel.Layout.Column = 1;
            app.RampCoordinateDropDown = uidropdown(rampGrid, ...
                'Items', {'Along ramp', 'Horizontal'}, ...
                'Value', 'Along ramp');
            app.RampCoordinateDropDown.Layout.Row = 4;
            app.RampCoordinateDropDown.Layout.Column = 2;
            app.RampPositionField = app.addNumericInput(rampGrid, 5, ...
                'Initial position (m)', 3.0, [0 Inf]);
            app.RampVelocityField = app.addNumericInput(rampGrid, 6, ...
                'Initial velocity (m/s)', 0.0, [-Inf Inf]);
            rampStopLabel = uilabel(rampGrid, 'Text', 'Final condition', ...
                'FontColor', [0.24 0.28 0.34]);
            rampStopLabel.Layout.Row = 7;
            rampStopLabel.Layout.Column = 1;
            app.RampStopConditionDropDown = uidropdown(rampGrid, ...
                'Items', {'Natural End', 'Maximum Time', ...
                          'Position Reached', 'Speed Reached', ...
                          'Object Stops'}, ...
                'Value', 'Natural End', ...
                'Tag', 'RampStopCondition', ...
                'ValueChangedFcn', @(~, ~) app.finalConditionChanged());
            app.RampStopConditionDropDown.Layout.Row = 7;
            app.RampStopConditionDropDown.Layout.Column = 2;
            app.RampStopValueLabel = uilabel(rampGrid, ...
                'Text', 'Target value', ...
                'FontColor', [0.24 0.28 0.34]);
            app.RampStopValueLabel.Layout.Row = 8;
            app.RampStopValueLabel.Layout.Column = 1;
            app.RampStopValueField = uieditfield(rampGrid, 'numeric', ...
                'Value', 5.0, 'Limits', [-Inf Inf], ...
                'Tag', 'RampStopValue');
            app.RampStopValueField.Layout.Row = 8;
            app.RampStopValueField.Layout.Column = 2;

            app.CollisionPanel = uipanel(inputGrid, ...
                'Title', 'Collision Parameters', 'FontWeight', 'bold', ...
                'BackgroundColor', [0.97 0.98 1]);
            app.CollisionPanel.Layout.Row = 5;
            collisionGrid = uigridlayout(app.CollisionPanel, [12 2]);
            collisionGrid.RowHeight = repmat({29}, 1, 12);
            collisionGrid.ColumnWidth = {'1x', 155};
            collisionGrid.Padding = [10 6 10 6];
            collisionGrid.RowSpacing = 3;

            app.CollisionMass1Field = app.addNumericInput(collisionGrid, 1, ...
                'Object 1 mass (kg)', 3.0, [eps Inf]);
            app.CollisionMass2Field = app.addNumericInput(collisionGrid, 2, ...
                'Object 2 mass (kg)', 1.0, [eps Inf]);
            app.CollisionPosition1Field = app.addNumericInput(collisionGrid, 3, ...
                'Object 1 position (m)', 0.0, [-Inf Inf]);
            app.CollisionPosition2Field = app.addNumericInput(collisionGrid, 4, ...
                'Object 2 position (m)', 1.0, [-Inf Inf]);
            app.CollisionVelocity1Field = app.addNumericInput(collisionGrid, 5, ...
                'Object 1 velocity (m/s)', 2.0, [-Inf Inf]);
            app.CollisionVelocity2Field = app.addNumericInput(collisionGrid, 6, ...
                'Object 2 velocity (m/s)', 1.0, [-Inf Inf]);

            collisionTypeLabel = uilabel(collisionGrid, ...
                'Text', 'Collision type', 'FontColor', [0.24 0.28 0.34]);
            collisionTypeLabel.Layout.Row = 7;
            collisionTypeLabel.Layout.Column = 1;
            app.CollisionTypeDropDown = uidropdown(collisionGrid, ...
                'Items', {'Perfectly Elastic', 'Perfectly Inelastic', ...
                          'Imperfectly Inelastic'}, ...
                'Value', 'Perfectly Elastic', ...
                'ValueChangedFcn', @(~, ~) app.collisionTypeChanged());
            app.CollisionTypeDropDown.Layout.Row = 7;
            app.CollisionTypeDropDown.Layout.Column = 2;
            app.RestitutionField = app.addNumericInput(collisionGrid, 8, ...
                'Restitution e', 0.5, [0 1]);
            app.CollisionFrictionField = app.addNumericInput(collisionGrid, 9, ...
                'Surface friction', 0.0, [0 Inf]);
            app.GravityField = app.addNumericInput(collisionGrid, 10, ...
                'Gravity (m/s^2)', 9.81, [eps Inf]);
            collisionStopLabel = uilabel(collisionGrid, ...
                'Text', 'Final condition', ...
                'FontColor', [0.24 0.28 0.34]);
            collisionStopLabel.Layout.Row = 11;
            collisionStopLabel.Layout.Column = 1;
            app.CollisionStopConditionDropDown = uidropdown(collisionGrid, ...
                'Items', {'Maximum Time', 'Object 1 Position', ...
                          'Object 2 Position', 'Object 1 Speed', ...
                          'Object 2 Speed', 'Both Objects Stop'}, ...
                'Value', 'Maximum Time', ...
                'Tag', 'CollisionStopCondition', ...
                'ValueChangedFcn', @(~, ~) app.finalConditionChanged());
            app.CollisionStopConditionDropDown.Layout.Row = 11;
            app.CollisionStopConditionDropDown.Layout.Column = 2;
            app.CollisionStopValueLabel = uilabel(collisionGrid, ...
                'Text', 'Maximum time (s)', ...
                'FontColor', [0.24 0.28 0.34]);
            app.CollisionStopValueLabel.Layout.Row = 12;
            app.CollisionStopValueLabel.Layout.Column = 1;
            app.CollisionStopValueField = uieditfield(collisionGrid, ...
                'numeric', 'Value', 10.0, 'Limits', [-Inf Inf], ...
                'Tag', 'CollisionStopValue');
            app.CollisionStopValueField.Layout.Row = 12;
            app.CollisionStopValueField.Layout.Column = 2;

            buttonGrid = uigridlayout(inputGrid, [1 3]);
            buttonGrid.Layout.Row = 6;
            buttonGrid.ColumnWidth = {'1x', '1x', '1x'};
            buttonGrid.Padding = [0 2 0 0];
            app.RunButton = uibutton(buttonGrid, 'push', ...
                'Text', 'Run', 'FontWeight', 'bold', ...
                'BackgroundColor', [0.12 0.46 0.78], ...
                'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(~, ~) app.runSimulation());
            app.StopButton = uibutton(buttonGrid, 'push', ...
                'Text', 'Stop', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~, ~) app.requestStop());
            app.ResetButton = uibutton(buttonGrid, 'push', ...
                'Text', 'Reset', ...
                'ButtonPushedFcn', @(~, ~) app.resetInputs());

            outputGrid = uigridlayout(mainGrid, [3 1]);
            outputGrid.Layout.Column = 2;
            outputGrid.RowHeight = {28, 300, '1x'};
            outputGrid.Padding = [8 6 8 8];
            outputGrid.RowSpacing = 6;
            outputGrid.BackgroundColor = [1 1 1];

            visualizationLabel = uilabel(outputGrid, ...
                'Text', 'Visualization', 'FontWeight', 'bold', ...
                'FontSize', 14, 'FontColor', [0.20 0.24 0.30]);
            visualizationLabel.Layout.Row = 1;

            app.AnimationAxes = uiaxes(outputGrid);
            app.AnimationAxes.Layout.Row = 2;
            app.AnimationAxes.Color = [0.985 0.99 1];

            app.OutputTabs = uitabgroup(outputGrid);
            app.OutputTabs.Layout.Row = 3;
            app.PositionTab = uitab(app.OutputTabs, 'Title', 'Position');
            app.SpeedTab = uitab(app.OutputTabs, 'Title', 'Speed');
            app.MomentumTab = uitab(app.OutputTabs, 'Title', 'Momentum');
            app.EnergyTab = uitab(app.OutputTabs, 'Title', 'Energy');

            positionGrid = uigridlayout(app.PositionTab, [1 1]);
            positionGrid.Padding = [5 5 5 5];
            app.PositionAxes = uiaxes(positionGrid);
            speedGrid = uigridlayout(app.SpeedTab, [1 1]);
            speedGrid.Padding = [5 5 5 5];
            app.SpeedAxes = uiaxes(speedGrid);
            momentumGrid = uigridlayout(app.MomentumTab, [1 1]);
            momentumGrid.Padding = [5 5 5 5];
            app.MomentumAxes = uiaxes(momentumGrid);
            energyGrid = uigridlayout(app.EnergyTab, [1 1]);
            energyGrid.Padding = [5 5 5 5];
            app.EnergyAxes = uiaxes(energyGrid);

            footerPanel = uipanel(rootGrid, 'BorderType', 'none', ...
                'BackgroundColor', [1 1 1]);
            footerPanel.Layout.Row = 3;
            footerGrid = uigridlayout(footerPanel, [2 2]);
            footerGrid.RowHeight = {30, '1x'};
            footerGrid.ColumnWidth = {26, '1x'};
            footerGrid.Padding = [12 6 12 8];
            footerGrid.RowSpacing = 2;
            app.StatusLamp = uilamp(footerGrid, ...
                'Color', [0.20 0.62 0.34]);
            app.StatusLamp.Layout.Row = 1;
            app.StatusLamp.Layout.Column = 1;
            app.StatusLabel = uilabel(footerGrid, 'Text', 'Ready', ...
                'FontWeight', 'bold', 'FontColor', [0.20 0.24 0.30]);
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 2;
            app.ResultsTextArea = uitextarea(footerGrid, ...
                'Editable', 'off', 'FontName', 'Menlo', 'FontSize', 11, ...
                'BackgroundColor', [0.975 0.98 0.99]);
            app.ResultsTextArea.Layout.Row = 2;
            app.ResultsTextArea.Layout.Column = [1 2];

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = PhysicsTeachingApp
            app.createComponents();
            registerApp(app, app.UIFigure);
            app.startup();

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure)
            end
        end
    end
end
