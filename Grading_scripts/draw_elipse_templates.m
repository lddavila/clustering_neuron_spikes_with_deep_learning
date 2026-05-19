function [] = draw_elipse_templates(config)

dir_to_save_templates_to =config.TEMPLATE_CLUSTER_FP;

%First Draw The Circle
x_center = 0;
y_center = 0;
a = 1; % Semi-major axis
b = 1; % Semi-minor axis
theta = linspace(0, 4*pi, 100);
phi = pi/4; % Rotation angle (in radians)


% Parametric equations for the ellipse
x = x_center + a * cos(theta);
y = y_center + b * sin(theta);

R = [cos(phi) -sin(phi); sin(phi) cos(phi)];
rotated_coords = R * [x; y];
x_rot = rotated_coords(1, :);
y_rot = rotated_coords(2, :);


% Now plot and save the circle picture
close all;

the_figure = figure;
set(the_figure, 'Position', [100 100 800 600]);
k = boundary(x',y',0);
f = fill(x(k), y(k),'k');
axis equal;
axis off;
saveas(f,dir_to_save_templates_to(5))
close all;

% now draw the elipse templates
rotation_angles =[0,(3*pi)/4, pi/4,pi/2] ;
for i=1:size(rotation_angles,2)
    x_center = 0;
    y_center = 0;
    a = 3; % Semi-major axis
    b = 1; % Semi-minor axis
    theta = linspace(0, 4*pi, 100);
    phi = rotation_angles(i); % Rotation angle (in radians)


    % Parametric equations for the ellipse
    x = x_center + a * cos(theta);
    y = y_center + b * sin(theta);

    R = [cos(phi) -sin(phi); sin(phi) cos(phi)];
    rotated_coords = R * [x; y];
    x_rot = rotated_coords(1, :);
    y_rot = rotated_coords(2, :);
    the_figure = figure;
    set(the_figure, 'Position', [100 100 800 600]);
    k = boundary(x_rot',y_rot',0);
    f = fill(x_rot(k),y_rot(k),'k');
    axis equal
    axis off;
    saveas(f,dir_to_save_templates_to(i));
    close all;
end
end