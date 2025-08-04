function [agent,critic,obs_info,action_info] = get_agent_and_critique_net_for_verbose_states(num_features,num_neurons_per_layer,num_layers,epsilon_num)

obs_info = rlNumericSpec([1,num_features]);
action_info = rlFiniteSetSpec([0,1,-1]);

obs_path = [featureInputLayer(prod(obs_info.Dimension))];
for i=1:num_layers
    obs_path = [obs_path,fullyConnectedLayer(num_neurons_per_layer),leakyReluLayer];
end
obs_path = [obs_path,...
    fullyConnectedLayer(num_neurons_per_layer),...
    leakyReluLayer,...
    fullyConnectedLayer(num_neurons_per_layer,Name="obs_out")];

act_path = [featureInputLayer(prod(action_info.Dimension))];
for i=1:num_layers
    act_path = [act_path,fullyConnectedLayer(num_neurons_per_layer),leakyReluLayer];
end
act_path = [act_path,...
    fullyConnectedLayer(num_neurons_per_layer),...
    leakyReluLayer,...
    fullyConnectedLayer(num_neurons_per_layer,Name="action_out")
    ];


common_path = [concatenationLayer(1,2,Name="cct")
    fullyConnectedLayer(num_neurons_per_layer)
    leakyReluLayer
    fullyConnectedLayer(1,Name="output")];

net = dlnetwork;
net= addLayers(net,obs_path);
net= addLayers(net,act_path);
net = addLayers(net,common_path);

net = connectLayers(net,"obs_out","cct/in1");
net = connectLayers(net,"action_out","cct/in2");

net = initialize(net);

critic = rlQValueFunction(net,obs_info,action_info,'ObservationInputNames','input','ActionInputNames','input_1');
agent_options = rlQAgentOptions;

agent = rlQAgent(critic,agent_options);

agent.AgentOptions.EpsilonGreedyExploration.Epsilon = epsilon_num;
% act = getAction(agent,{randi(numel(obs_info.Elements))});


% env = rlFunctionEnv();

end