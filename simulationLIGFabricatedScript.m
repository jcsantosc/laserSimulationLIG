%% Using the models obtained through Simulink simulation, an algorithm has been devised to predict crucial characteristics of LIG. This algorithm provides valuable insight into LIG's conductivity, sheet resistance, and morphology, taking into account the myriad configurable and multivariate laser parameters involved in the fabrication process. The algorithm flowchart, as depicted in Figure XX outlines its step-by-step operation. Initially, the laser fluency, power density and peak power values are obtained from the laser configurable and fixed parameters through the simulation. These values serve as foundational indicators. Subsequently, the algorithm classifies the whether the resulting sample exhibits conductivity or not, acting as a fundamental binary distinction. For samples deemed conductive, the algorithm proceeds to calculate the sheet resistance, a critical metric in assessing the material's electrical performance. Furthermore, the algorithm also provides insights into the morphology of the conductive LIG sample, enabling researchers and engineers to gain a comprehensive understanding of its structural properties. This predictive algorithm is instrumental in streamlining the LIG fabrication process and allows for informed decision-making in optimizing its properties for specific applications.
%% Set configurable laser parameters
power = 10 ; % duty cycle laser power (%)
speed = 400; % laser speed (mm/s)
F = 80000; % laser frequency (Hz)
%% Set fixed laser parameters
tau = 40e-6; % laser raisng time (s)
beamSize = 0.116; % laser beam size (mm)
powerMax = 25; % laser power max (W)
%% Set drawing line distance
distance = 6; % drawing line distance (mm)
%% Calculate data for simulation
dutyCycle = power/100; % duty cycle is power/100
t = distance/speed; % time for laser draw line (s)
ton= (dutyCycle*(1/F)); % time On for one cycle (s)
tof = (1-dutyCycle)*(1/F); % time off for one cycle (s)
spike = distance/(speed/F); % number of laser shots in the line
Spike1P = beamSize/(speed/F); % number of laser shots in laser beam size
spikes = distance/(speed/F);
L1POn = (((dutyCycle*(1/F)*speed)+ beamSize)); % length of the one pulseON on the sustrate (mm)
L1Ptot = (((1/F)*speed)+ beamSize); % length of the one cycle (On+OFF) on the sustrate (mm)
L1Pof = L1Ptot- L1POn; % length of the one pulseOFF on the sustrate (mm)
LC1POn = ((dutyCycle*(1/F)*speed)); % length of the one pulseON without considering the beam size (mm)
LC1Ptot = ((1/F)*speed); % length of the one cycle without considering the beam size (mm)
LC1Pof = LC1Ptot-LC1POn; % length of the one pulseOFF without considering the beam size (mm)
LIG = (((dutyCycle*(1/F)*speed)+ beamSize))*spike; % length of the total drawing without considering the overlaping (mm)
%% Laser Simulation
dataSim = sim("laserSim.slx"); %Simulates the welding process using a Simulink model
ts = t/length(dataSim.tout);
%% Calculate energy delivered
eTot = trapz(dataSim.tout, dataSim.a);  % computes the energy delivered to the draw line using the trapz function.
midtime = (floor(spike/2))*(1/F); % middle time of spike
midtimeindex = find(dataSim.tout == midtime); % index middle time of spike
midontime = midtime + ((1/F)*dutyCycle); % middle time Pulse On of spike
midontimeindex = find(dataSim.tout == midontime); % index middle time Pulse On of spike
midofftime = ((floor(spike/2))+1)*(1/F); % middle time Pulse Off of spike
midofftimeindex = find(dataSim.tout == midofftime); % index middle time Pulse off of spike
eon1p = trapz(dataSim.tout(midtimeindex:midontimeindex), dataSim.a(midtimeindex:midontimeindex)); % energy for one pulse while the laser is ON (J)
eof1p = trapz(dataSim.tout(midontimeindex:midofftimeindex), dataSim.a(midontimeindex:midofftimeindex)); % energy for one pulse while the laser is OFF (J), beacuse of the laser raising time we have energy while laser off
Eofvson = eof1p./eon1p; % ratio of energy off/on (J)
Eonvsof = eon1p/eof1p; % ratio of energy on/off (J)
Etot = eof1p + eon1p; % total energy of one pulse (J)
%% Calculate area
Areaon = (pi*((beamSize/2)^2))+(LC1POn.*(beamSize)); % area which the energy of one pulseON delivered (mm^2)
Areatot = (pi*((beamSize/2)^2))+(LC1Ptot.*(beamSize)); % area which the energy the one cycle delivered(mm^2)
Areaof = (pi*((beamSize/2)^2))+(LC1Pof*(beamSize)); % area which the energy of one pulseOFF delivered(mm^2)
%% Calculate fluence
FluencyOn = eon1p/Areaon; % fluency of one pulseON (J/mm^2)
FluencyOff = eof1p/Areaof ; % fluency of one pulseOFF (J/mm^2)
FluencyTot = Etot/Areatot; % fluency of one cycle (J/mm^2)
Fluencydraw = FluencyTot*spikes; % acumalated fluency for whole of de line (J/mm^2)
%% Calculate power density
Powerdensitypulse = FluencyTot/(ton+tof); % power density of one pulse (W/mm^2)
Powerdensitydraw = Powerdensitypulse*spikes; % acumalated power density for whole of line (W/mm^2)
%% Calculate power peak
if (tof > 100e-6)
    peakpower = Etot/(ton+(1e-4));
else
    peakpower = Etot/(ton+tof);
end
if Spike1P > 1
    acumulatedpulsed = Spike1P;
else
    acumulatedpulsed = 1;
end
acumulatedpowerpeak = peakpower*acumulatedpulsed; % acumalated power peak for whole of line (W)
%% Estimation characteristics of LIG
load("machineLearningModels.mat") % load machine learning models
tableSim = table(power,speed,F,Fluencydraw,peakpower,acumulatedpowerpeak,'VariableNames',["powerLaser","speedLaser","frequencyLaser","fluencyDrawLine","powerPeakOnePulse","powerPeakAcumlated"]);
yres = CLMR.predictFcn(tableSim); % Conductivity classification of drawing line
if (yres == true) % Condutive line
    ramanCl = CLMRaman.predictFcn(tableSim); % Morphology classification of LIG
    if (ramanCl == "WF")
        morphology = "wolly fibers";
    elseif (ramanCl == "CN")
        morphology = "cellular networks";
    else
        morphology = "porous formations";
    end
    res = RLMRA.predictFcn(tableSim); % Estimation sheet resistance of LIG
    fprintf("The morphology of the sample is %s\n",morphology);
    fprintf("The sheet resistance of the sample is %.2f Ω*mm\n",res);
else % Not condutive line
    fprintf("The sample is not conductive\n");
end

%% Simulation drawing line laser
num_circles = spikes;
diameter = beamSize; % mm
line_length = distance; % mm
X = LC1Ptot; % Set the distance between the centers of the red circles in mm
Y = LC1POn; % Set the distance between the centers of the blue and red circles in mm
Y2 = LC1Pof;
%% Plot the Laser Spot
figure;
hold on
for i = 1:num_circles
    % Plot the Laser spot while it is ON
    x = ((i - 1) * (X)) - ((diameter/2)); % Distance between the centers of the red circles is X
    y = Y + (diameter);
    y2 = Y2 + (diameter);
    rectangle('Position', [x, 0, y, diameter], 'Curvature',1 , 'FaceColor', 'r', 'EdgeColor', 'C', 'LineWidth', 0.1);
end
hold off
axis equal
xlabel('Distance of the Laser Draw (mm)');
ylabel('Position on the line (mm)');
axis([0 6 0 3]);
