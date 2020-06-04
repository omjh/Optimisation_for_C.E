%-----------Optimisation-----------

%Date: 02/06/20
%Desciption: Matlab Code Written for a Optimisation project for C.E
%Author: Oliver Hoare

%---------Fitting Functions To data-------------

%----Open Data----
Survey_data  = readtable('Festival Tent Contaminants and Tonics');

%----Territory Function----
Territory_data = [];

for i = 2:8
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a);
    Territory_data = [Territory_data;a2];     
end

x = [0 1 5 10 20 50 100]';


%scatter(x, Territory_data)
%figure
% scatter(x,Territory_data)
% hold on
territory_func = fit(x, Territory_data, 'poly3')
%plot(territory_func);

% title('Territory')
% hold off


%----Hygiene Function----

%--Function for Dirt --

dirt_hygiene_data = [];
freq_dirt = 1;
for i = 9:13
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a)/100;
    dirt_hygiene_data = [dirt_hygiene_data ;a2];     
end

x2 = [1 2 3 4 5]';
%figure
%scatter(x2,dirt_hygiene_data)
% hold on 
dirt_func = fit(x2,dirt_hygiene_data, 'poly3')
%plot(dirt_func)
% title('Dirt Hygiene State')
% hold off

%--function for stain--
stain_hygiene_data = [];
for i = 14:18
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a)/100;
    stain_hygiene_data = [stain_hygiene_data ;a2];     
end

%figure
%scatter(x2,stain_hygiene_data)
% hold on 
stain_func = fit(x2,stain_hygiene_data, 'poly3')
%plot(stain_func)
% title('Stain Hygiene State')
% hold off

%--function odour--
odour_hygiene_data = [];
for i = 19:23
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a)/100;
    odour_hygiene_data = [odour_hygiene_data ;a2];     
end

%figure
%scatter(x2,odour_hygiene_data)
% hold on 
odour_func = fit(x2,odour_hygiene_data, 'poly3')
% %plot(odour_func)
% title('Odour Hygiene State')
% hold off

%--No Knowledge hygiene Function--
nk_hygiene_data = [];
for i = 24:28
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a)/100;
    nk_hygiene_data = [nk_hygiene_data ;a2];     
end

%figure
%scatter(x2,nk_hygiene_data)
% hold on 
nk_func = fit(x2,nk_hygiene_data, 'poly3')
%plot(nk_func)
% title('Unknown Hygiene State')
% hold off


%----Cleaning Cost Function----
cost = [1.25 2.5 3.75 5]';
cost_func = fit([1 2 3 4]', cost, 'poly1');
%plot(cost_func)

%----Energy Tent Clean----
energy_t_clean = [0 0 0.25 1.0 1.2]';
energy_func = fit(x2, energy_t_clean, 'poly2');

%----Technical UX Figures----
technical_data = [];
for i = 29:31
    a = table2array(rmmissing(Survey_data(:,i)));
    a2 = median(a)/100;
    technical_data = [technical_data ;a2];     
end


%------Tests------
a = zeros(100,3);
b = [];
for i = 1:100
    a(i,1) = i;
    a(i,2) = 50;
    a(i,3) = 4;
    b(i) = UX(a(i,:), territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data);
end
% 
% figure
% scatter(a(:,1), b)


%-------OPTIMISATION!!-------
fun = @(x)[Eco(x, energy_func);-Econ(x, cost_func, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data);-UX(x, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data)];
lb = [1,20,0];
ub = [60, 50, 5];
pareto_size = 200;


options = optimoptions('paretosearch','Display', 'iter', 'PlotFcn',{'psplotparetof' 'psplotparetox'},'ParetoSetSize',200);
%[solution, fval] = paretosearch(fun,3,[],[],[],[],lb,ub,[],options);

plot_space(solution,pareto_size,fval);


%Create Objective Plot From Normalised Numbers

% figure
% a = Eco_Linear(solution, fval, 80);
% scatter(a(:,1),-a(:,2))
% hold on
% xlabel('Environmental Impact')
% ylabel('Financial Impact')
% scatter(fval(:,1), -fval(:,2))
% 
% a = [];
% for i = 1:60
%     a = [a , Eco([i,50,5])];
%     c = max(a)
% end
% z = 1:60;
% plot(z,a)

%for normalisation
%[solution,max] = fmincon(@(x)(-UX(x, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data)), [10, 30, 5],[],[],[],[],lb,ub)


%------------Functions for Optimisation----------------

function E_total = Eco(x,energy_func)
    %Eneergy Constants
    E_Man = 266; %MJ
    E_Trans = 4.9; 
    E_EoL = 0.68;
    E_clean = energy_func(x(:,3));
    E_Trans_UK = 1.68;
    %See EQn in Report
    E_total = (1+ 60/x(:,1))*E_Man + (1+ 60/x(:,1))*E_Trans + (1+ 60/x(:,1))*E_EoL + x(:,1)*E_clean + x(:,1)*E_Trans_UK;   
    
    %normalisation
    E_total = (E_total -  643.9600)/(16570 - 643.9600);
end

function Value = Econ(x, cost_func, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data)
    %Cost Constants
    C_wholesale = 8; %£
    C_UK_transport = 0.6;
    C_cleaning  = cost_func(x(:,3));
    C_storage = 40;
    a = UX(x, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data)/(2*(x(:,2)));
    Demand = 22500*a;
    
    Cost  = C_wholesale + 2*C_UK_transport + C_cleaning + C_storage/Demand;
    Value = Demand*(x(:,2) - Cost);
    
    %normalisation
    Value = (Value - 40.0074)/(9.4213e+03- 40.0074);
end

function UX = UX(x, territory_func, dirt_func, stain_func, odour_func, nk_func, technical_data)
    %---Frequency of events----
    freq_dirt = 1;
    freq_stain = 0.1;
    freq_odour = 0.02;
    freq_bzip = 0.02;
    freq_hole = 0.02;
    freq_fade = 1/60;
    

    Territory = territory_func(x(:,1)-1);   
    Hygiene = 100*(dirt_func(x(:,3))^(((x(:,1)-1)*freq_dirt)) + stain_func(x(:,3))^(((x(:,1)-1)*freq_stain)) + odour_func(x(:,3))^(((x(:,1)-1)*freq_odour)) + nk_func(x(:,3))^(x(:,1)-1))/4;
    Technical = (100*(technical_data(1,:))^((x(:,1)-1)*freq_bzip) + 100*technical_data(2,:)^(((x(:,1)-1)*freq_hole)) + 100*technical_data(2,:)^(((x(:,1)-1)*freq_fade)))/3;
    
    UX = (Technical + Territory + Hygiene)/3;
    
    %normalisation
    UX = (UX - 40.9851)/(99.4871 - 40.9851);
end

function linear = Eco_Linear()
    E_Man = 266; %MJ
    E_Trans = 4.9; 
    E_EoL = 0.68;
    E_Trans_UK = 1.68;
    linear = 60*(E_Man + E_Trans + E_EoL +  E_Trans_UK )  
end

function plot_space(solution, pareto_size,fval)
    for i = 1:pareto_size   
        Environ(i) = ((fval(i,1)*(16570 - 643.9600)) + 643.9600)';
        Econom(i) = ((-fval(i,2)*(9.4123e+05-1.5059e+05) + 1.5059e+05))';
        UserX(i) =  (-fval(i,3)*(99.4871 - 40.9851)+ 40.9851);
    end

    figure 
    scatter(Econom,Environ)
    xlabel('Economic')
    ylabel('Environmental Impact Per 60 Rentals / MJ')

    figure 
    scatter(UserX,Environ)
    xlabel('User Experience')
    ylabel('Environmental Impact Per 60 Rentals / MJ')

    figure 
    scatter(Econom,UserX)
    xlabel('Economic')
    ylabel('User Experience')

    figure 
    scatter3(Econom,Environ,UserX)
    xlabel('Economic')
    ylabel('Environmental Impact Per 60 Rentals / MJ')
    zlabel('User Experience')
    
%Design Space Variable Plots
    figure
    scatter(solution(:,1)',solution(:,3)')
    xlabel('Number of Uses')
    ylabel('Quality of Cleaning')
    title('Parameter Space Solution Plot: Number of Uses vs Quality of Cleaning')

    figure
    scatter(solution(:,1)',solution(:,2)')
    xlabel('Number of Uses')
    ylabel('Selling Price /£')
    title('Parameter Space Solution Plot: Number of Uses vs Selling Price')

    figure
    scatter(solution(:,2)',solution(:,3)')
    xlabel('Selling Price /£')
    ylabel('Quality of Cleaning')
    title('Parameter Space Solution Plot: Selling Price vs Quality of Cleaning')
    
    index = find(Environ == 2589.8)
    lin = Eco_Linear()
    percentage = 1 - 2600/lin
end




