%  20200307 Chen 542254418
% 三个做图都是用的有限差分法，第一个图虽然没有控制，但是不同的初值未必有解析解，所以都求数值解
% 空间差分方法： w_xx(x,t) = (w(x+dx,t) - 2*w(x,t) + w(x-dx,t))/（dx^2)
% 空间四阶差分： w_xxxx(x,t) = (w(x+2*dx,t) - 4*w(x+dx,t) + 6*w(x,t) - 4*w(x-dx,t) + w(x-2*dx,t))/(dx^4)


clear
clc
% close all

First_picture  = 1;    % 计算第一种情况 无控制
draw_pic_1     = 0;    % 绘制第一种情况图，包括系统状态；端点w(1,t)状态
Second_picture = 1;    % 计算第二种情况 端点速度反馈控制  w_{xxx}(1,t) = k*w_t(1,t)
draw_pic_2     = 0;    % 绘制第二种情况图，包括系统状态；端点w(1,t)状态；系统输入
Third_picture  = 0;    % 计算第三种情况 端点速度反馈时延控制  w_{xxx}(1,t) = k*w_t(1,t-tau)
draw_pic_3     = 0;    % 绘制第三种情况图，包括系统状态；端点w(1,t)状态；系统输入
Forth_picture  = 1;    % 计算第四种情况 端点积分时延控制   最好的时间步长是0.02，计算核函数的时间步长是0.0001
draw_pic_4     = 0;    % 绘制第四种情况图，包括系统状态；端点w(1,t)状态；系统输入

Final_pic      = 1;    % 绘制四种情况w(1,t)

%% 参数设置

t = 10;
dt = 0.001;
nt = t/dt;
N = 40;
dx = 1/N;
Tau = 1;
tau = Tau/dt;
x = 0:dx:1;
k = 5;      % 速度反馈参数

initial_state  = sin(pi*x);
initial_vector = cos(pi*x);


%% 第一个数值模拟
%  w_{tt}(x,t) + w_{xxxx}(x,t) = 0
%  w(0,t) = w_x(1,t) = w_{xx}(0,t) = w_{xxx}(1,t) = 0
%  这里的时间步长要小于10^(-4)，否则就收敛了

if First_picture
    
    if dt > 10^(-4)     % 这里一定要小于10^(-4)，否则就收敛了！！！！
        Dt = 10^(-4);
        Nt = t/Dt;
    else
        Dt = dt;
        Nt = nt;
    end
    
    
    w   = zeros(N+1,Nt+1);
    w_t = zeros(N+1,Nt+1);
    w(:,1)   = initial_state;
    w_t(:,1) = initial_vector;
    
    D4 = FDM_Matrix(N,dx);
    
    sys_1 = eye(N-3,N-3) + Dt^2*D4;
    
    for i = 2:Nt+1
        w(3:N-1,i) = sys_1\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1));
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i);
        w(N,i)   = w(N-1,i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    w_pic_1  = w;
    wt_pic_1 = w_t;
    nt_pic_1 = Nt;
    dt_pic_1 = Dt;
    
    if draw_pic_1
        figure                     % 第一个情况的动态图
        [y,z]=meshgrid(0:Dt:t,x);
        mesh(z,y,w(:,:))   
        xlabel({'$x$'},'Interpreter','latex','FontSize',14)
        ylabel({'$t$'},'Interpreter','latex', 'FontSize',14)
        zlabel({'$w$'},'Interpreter','latex', 'FontSize',14)   
        title('dynamic behavior of w(x,t) without control')
        
        figure                     % 第一个情况w(1,t)的动态图
        plot(0:Dt:t,w(N+1,:));
        title('dynamic behavior of w(1,t)')
        xlabel('t')
        grid on
    end
    
    
    clear w w_t Nt Dt
end




%%   第二个数值模拟
%  w_{tt}(x,t) + w_{xxxx}(x,t) = 0
%  w(0,t) = w_x(1,t) = w_{xx}(0,t) =0
%  w_{xxx}(1,t) = k*w_t(1,t)
%  这里时间步长要大

if Second_picture
    
    if dt <= 10^(-3)
        Dt = 5*10^(-2);
        Nt = t/Dt;
    else
        Dt = dt;
        Nt = nt;
    end
    
    w   = zeros(N+1,Nt+1);
    w_t = zeros(N+1,Nt+1);
    w(:,1)   = initial_state;
    w_t(:,1) = initial_vector;
    
    U = zeros(1,Nt+1);
    D4 =  FDM_Matrix(N,dx);
    
    sys_2 = eye(N-3,N-3) + Dt^2*D4;
    
    
    
    for i = 2:Nt+1
        U(i) = k*w_t(N+1,i-1);         % w_{xxx}(1,t) = k*w_t(1,t)
        temp = [ zeros(N-5,1); 2/3*dx^5; -2*dx^5]*U(i);
        w(3:N-1,i) = sys_2\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1) - Dt^2*temp);
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i) + 2/3*dx^5*U(i);
        w(N,i)   = w(N-1,i) + 2/3*dx^5*U(i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    if draw_pic_2
        figure                    % 第二个情况的动态图
        [y,z]=meshgrid(0:Dt:t,x);
        mesh(z,y,w(:,:))   
        xlabel({'$x$'},'Interpreter','latex','FontSize',14)
        ylabel({'$t$'},'Interpreter','latex', 'FontSize',14)
        zlabel({'$w$'},'Interpreter','latex', 'FontSize',14)   
        title('dynamic behavior of w(x,t) with state feedback control')
        
        figure                    % 第二个情况w(1,t)的动态图
        plot(0:Dt:t,w(N+1,:));
        title('dynamic behavior of w(1,t)')
        xlabel('t')
        grid on
        
        figure                    % 第二个情况输入U(t)的动态图
        plot(0:Dt:t,U(:));
        title('system input U(t)')
        xlabel('t')
        grid on
    end
    
    w_pic_2  = w;
    wt_pic_2 = w_t;
    nt_pic_2 = Nt;
    dt_pic_2 = Dt;
    U_pic_2  = U;
    
    clear w w_t Nt Dt U temp
end

%%  第三个情况
%  w_{tt}(x,t) + w_{xxxx}(x,t) = 0
%  w(0,t) = w_x(1,t) = w_{xx}(0,t) =0
%  w_{xxx}(1,t) = k*w_t(1,t-tau)


if Third_picture
    
    if dt > 10^(-4)
        Dt = 1*10^(-4);
        Nt = t/Dt;
        tau = Tau/Dt;
    else
        Dt = dt;
        Nt = nt;
    end
    
    w   = zeros(N+1,Nt+1);
    w_t = zeros(N+1,Nt+1);
    w(:,1)   = initial_state;
    w_t(:,1) = initial_vector;
    
    U = zeros(1,Nt+1);
    U(1:tau) = sin((0:Dt:Tau-Dt)*pi);      % 控制器记忆
    
    D4 =  FDM_Matrix(N,dx);
    
    sys_3 = eye(N-3,N-3) + Dt^2*D4;
    
    
    for i = 2:tau
        temp = [ zeros(N-5,1); 2/3*dx^5; -2*dx^5]*U(i);
        w(3:N-1,i) = sys_3\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1) - Dt^2*temp);
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i) + 2/3*dx^5*U(i);
        w(N,i)   = w(N-1,i) + 2/3*dx^5*U(i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    for i = tau+1:Nt+1
        U(i) = k*w_t(N+1,i-tau);         % w_{xxx}(1,t) = k*w_t(1,t)
        temp = [ zeros(N-5,1); 2/3*dx^5; -2*dx^5]*U(i);
        w(3:N-1,i) = sys_3\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1) - Dt^2*temp);
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i) + 2/3*dx^5*U(i);
        w(N,i)   = w(N-1,i) + 2/3*dx^5*U(i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    if draw_pic_3
        figure
        [y,z]=meshgrid(0:Dt:t,x);
        mesh(z,y,w(:,:))   
        xlabel({'$x$'},'Interpreter','latex','FontSize',14)
        ylabel({'$t$'},'Interpreter','latex', 'FontSize',14)
        zlabel({'$w$'},'Interpreter','latex', 'FontSize',14)   
        
        figure
        plot(0:Dt:t,w(N+1,:));
        title('dynamic behavior of w(1,t)')
        xlabel('t')
        grid on
        
        figure
        plot(0:Dt:t,U(:));
        title('system input U(t)')
        xlabel('t')
        grid on
    end
    
    w_pic_3  = w;
    wt_pic_3 = w_t;
    nt_pic_3 = Nt;
    dt_pic_3 = Dt;
    U_pic_3  = U;
    
    clear w w_t Nt Dt U temp
end

%% 第四个情况
% w_{tt}(x,t) + w_{xxxx}(x,t) = 0
% w(0,t) = w_x(1,t) = w_{xx}(0,t) = 0
% w_{xxx}(1,t) = u(t-\tau)
% u(t) = - int^\tau_0 eta(\tau-s,1)u(t+s-\tau)ds + \int^1_0 eta_s(\tau,x)w(x,t)dx + \int^1_0 eta(\tau,x)w_t(x,t)dx
% eta_{ss}(x,s) + eta_{xxxx}(x,s) = 0
% eta(0,s) = eta_x(1,s) = eta_{xx}(0,s) = eta_{xxx}(1,s)=0
% eta(x,0) = 0,  eta_s(x,0) = k \delta(x-1)

if Forth_picture
    
    if dt < 2*10^(-2)
        Dt = 2*10^(-2);
        Nt = t/Dt;
        tau = Tau/Dt;
    else
        Dt = dt;
        Nt = nt;
    end
    
    w   = zeros(N+1,Nt+1);
    w_t = zeros(N+1,Nt+1);
    w(:,1)   = initial_state;
    w_t(:,1) = initial_vector;
    
    U = zeros(1,Nt+1);
    U(1:tau) = sin((0:Dt:Tau-Dt)*pi);      % 控制器记忆
    
    
    D4 =  FDM_Matrix(N,dx);
    
    DT = 10^(-4);
    sys_eta = eye(N-3,N-3) + DT^2*D4;
    eta   = zeros(N+1,Tau/DT+1);
    eta(N+1,1) = k;
    eta_s = zeros(N+1,Tau/DT+1);
    
    
    eta(N+1,2) = eta(N+1,1);
    eta(N-1,2) = eta(N+1,2);
    eta(N,2)   = eta(N+1,2);
    
    for i = 3:Tau/DT+1
        eta(3:N-1,i) = sys_eta\(eta(3:N-1,i-1) + Dt*eta_s(3:N-1,i-1));
        eta(2,i) = 0.5*eta(3,i);
        eta(N+1,i) = eta(N-1,i);
        eta(N,i)   = eta(N-1,i);
        eta_s(:,i) = (eta(:,i) - eta(:,i-1))/Dt;
    end
    
    p = eta(N+1,1:Dt/DT:Tau/DT);
    
%         figure       % 核函数图像
%         [y,z]=meshgrid(0:DT:Tau,x);
%         mesh(z,y,eta(:,:))   
%         xlabel({'$x$'},'Interpreter','latex','FontSize',14)
%         ylabel({'$t$'},'Interpreter','latex', 'FontSize',14)
%         zlabel({'$w$'},'Interpreter','latex', 'FontSize',14)   
    
    sys_4 = eye(N-3,N-3) + Dt^2*D4;
    
    for i = 2:tau     % 控制器记忆期间
        temp = [ zeros(N-5,1); 2/3*dx^5; -2*dx^5]*U(i);
        w(3:N-1,i) = sys_4\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1) - Dt^2*temp);
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i) + 2/3*dx^5*U(i);
        w(N,i)   = w(N-1,i) + 2/3*dx^5*U(i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    for i = tau+1:Nt+1
        U(i) = -p*fliplr(U(i-tau:i-1))'*dt + eta_s(:,tau+1)'*w(:,i-tau)*dx + eta(:,tau+1)'*w_t(:,i-tau)*dx;
        temp = [ zeros(N-5,1); 2/3*dx^5; -2*dx^5]*U(i);
        w(3:N-1,i) = sys_4\(w(3:N-1,i-1) + Dt*w_t(3:N-1,i-1) - Dt^2*temp);
        w(2,i) = 0.5*w(3,i);
        w(N+1,i) = w(N-1,i) + 2/3*dx^5*U(i);
        w(N,i)   = w(N-1,i) + 2/3*dx^5*U(i);
        w_t(:,i) = (w(:,i) - w(:,i-1))/Dt;
    end
    
    if draw_pic_4
        figure
        [y,z]=meshgrid(0:Dt:t,x);
        mesh(z,y,w(:,:))   
        xlabel({'$x$'},'Interpreter','latex','FontSize',14)
        ylabel({'$t$'},'Interpreter','latex', 'FontSize',14)
        zlabel({'$w$'},'Interpreter','latex', 'FontSize',14)   
        title('dynamic behavior of w(x,t) with integral-type feedback control')
        
        figure
        plot(0:Dt:t,w(N+1,:));
        title('dynamic behavior of w(1,t)')
        xlabel('t')
        grid on
        
        figure
        plot(0:Dt:t,U(:));
        title('system input U(t)')
        xlabel('t')
        grid on
    end
    
    w_pic_4  = w;
    wt_pic_4 = w_t;
    nt_pic_4 = Nt;
    dt_pic_4 = Dt;
    U_pic_4  = U;
    
    clear w w_t Nt Dt U temp
    
end



%% 四个图做对比
if Final_pic
    if First_picture && Second_picture && Third_picture && Forth_picture
        
        figure
        plot(0:dt_pic_1:t,w_pic_1(N+1,:))
        hold on
        plot(0:dt_pic_2:t,w_pic_2(N+1,:))
        plot(0:dt_pic_3:t,w_pic_3(N+1,:))
        plot(0:dt_pic_4:t,w_pic_4(N+1,:))
        xlabel('t')
        title('dynamic behavior of w(1,t)')
        grid on
        legend('without control','state feedback control without delay','state feedback control with delay','integral-type feedback control')
        
        figure
        plot(0:dt_pic_2:t,U_pic_2(:))
        hold on
        plot(0:dt_pic_4:t,U_pic_4(:))
        xlabel('t')
        title('dynamic behavior of input U(t)')
        grid on
        legend('state feedback control without delay','integral-type feedback control')
        
        
        
        
    elseif First_picture && Second_picture  && Forth_picture
        
        figure
        plot(0:dt_pic_1:t,w_pic_1(N+1,:))
        hold on
        plot(0:dt_pic_2:t,w_pic_2(N+1,:))
        plot(0:dt_pic_4:t,w_pic_4(N+1,:))
        xlabel('t')
        title('dynamic behavior of w(1,t)')
        grid on
        legend('without control','state feedback control without delay','integral-type feedback control')
        
    end
    
end



function [D] = FDM_Matrix(N,dx)
D4 = zeros(N-3,N-3);     % 受四阶差分影响，头尾的各两个点受边界条件影响，所以计算N+1-4个点
for i = 3:N-5
    D4(i,i-2) = 1;
    D4(i,i-1) = -4;
    D4(i,i)   = 6;
    D4(i,i+1) = -4;
    D4(i,i+2) = 1;
end
D4(1,1)     = 4;    % w(0,t) = 0
D4(1,2)     = -4;   % w_xx(0,t)=0, w_x(0,t)=w_x(dx,t), w(dx,t)=-1/2*w(2*dx,t)
D4(1,3)     = 1;
D4(2,1)     = -3.5;
D4(2,2)     = 6;    % w(1,t) = w(1-dx,t) = w(1-2*dx,t)
D4(2,3)     = -4;
D4(2,4)     = 1;
D4(N-4,N-6) = 1;
D4(N-4,N-5) = -4;
D4(N-4,N-4) = 6;
D4(N-4,N-3) = -3;
D4(N-3,N-5) = 1;
D4(N-3,N-4) = -4;
D4(N-3,N-3) = 3;

D4 = D4/(dx^4);

D = D4;
end    % 四阶差分矩阵，其中将边界条件放在里面
