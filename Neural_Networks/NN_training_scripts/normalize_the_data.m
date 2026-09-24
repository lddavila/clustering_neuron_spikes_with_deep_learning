function [current_train,current_test,current_val,data_to_be_routed,mu,sigma] = normalize_the_data(current_train,options)
arguments
    current_train table
    options.data_to_be_routed = []
    options.mu = []
    options.sigma = []
    options.current_test = [];
    options.current_val = [];
end
data_to_be_routed = options.data_to_be_routed;
if isempty(options.mu)
    mu = mean(current_train.grades,"omitnan");
    mu(isinf(mu)) = 0;
    mu(isnan(mu)) = 0;
else
    mu = options.mu;
end

if isempty(options.sigma)
    sigma = std(current_train.grades,0,1,'omitnan');
    sigma(isnan(sigma)) = 1;
    sigma(sigma==0) = 1;
else
    sigma = options.sigma;
end

if isempty(options.current_test)
    current_test = [];
else
    current_test = options.current_test;
end
if isempty(options.current_val)
    current_val = [];
else
    current_val = options.current_val;
end

current_train_grades = current_train.grades;
current_train_grades(isnan(current_train_grades)) = 0;
current_train_grades(isinf(current_train_grades)) = 0;
current_train_grades = (current_train_grades- mu)./ sigma;
current_train.grades = current_train_grades;

if ~isempty(current_val)
    current_val_grades = current_val.grades;
    current_val_grades(isnan(current_val_grades)) = 0;
    current_val_grades(isinf(current_val_grades)) = 0;
    current_val_grades = (current_val_grades- mu) ./ sigma;
    current_val.grades = current_val_grades;
end
if ~isempty(current_test)
    current_test_grades = current_test.grades;
    current_test_grades(isnan(current_test_grades)) = 0;
    current_test_grades(isinf(current_test_grades)) = 0;
    current_test_grades = (current_test_grades-mu) ./ sigma;
    current_test.grades = current_test_grades;
end
if ~isempty(data_to_be_routed)
    data_to_be_routed_grades = data_to_be_routed.grades;
    data_to_be_routed_grades = (data_to_be_routed_grades -mu) ./ sigma;
    data_to_be_routed_grades(isnan(data_to_be_routed_grades)) = 0;
    data_to_be_routed_grades(isinf(data_to_be_routed_grades)) = 0;
    data_to_be_routed.grades = data_to_be_routed_grades;
end
end