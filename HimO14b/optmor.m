function PV = optmor(P,A,B,C,D,F,T,R,X,U,S,q,y)
% optmor (Version 1.0)
% by Christian Himpe, 2013,2014 ( http://wwwmath.uni-muenster.de/u/himpe )
% released under BSD 2-Clause License ( opensource.org/licenses/BSD-2-Clause )
%
% About:
%  optmor (OPTimization-based Model Order Reduction)
%  reduces simultaneously parameters and states of
%  of a dynamic system of the following type:
%
%  x' = Ax + Bu + F
%  y  = Cx + Du
%
%  A in R^NxN
%  B in R^NxM
%  C in R^OxN
%  D in R^OxM
%  F in R^N
%
% Parameters:
%  (vector) P : parameter prior mean
%  (matrix) A : system matrix (states x states) 
%  (matrix) B : input matrix (states x inputs)
%  (matrix) C : output matrix (outputs x states)
%  (matrix) D : feed-forward matrix (outputs x inputs)
%  (vector) F : source term (states x 1)
%  (vector) T : timing [start,step,stop]
%  (scalar) R : reduced state dimension or error bound
%  (vector) X : initial value (states x 1)
%  (matrix) U : input data (inputs x timesteps)
%  (matrix) S : prior covariance matrix (parameters x parameters)
%  (vector) q : configuration (8 x 1) {optional}
%               * reduction target (Dimension=0,Error=1) 
%               * state selection (POD=0,MEAN=1,LAST=2,POD-GREEDY=3)
%               * use trust region (No=0,Yes=1)
%               * use data driven reduction (No=0,Yes=1,Excl=2)
%               * optimization norm (0(=Inf),1,2,...)
%               * orthogonalization type (QR=0,SVD=1)
%               * integration order (Euler=0,Adams-Bashforth=1,Ralsron=2,Custom=-1)
%               * regularization (l2=0,l1=1,tr=2,off=3)
%               * parameter inclusion (seq=0,proj=1)
%  (matrix) y : experimental data (outputs x timesteps) {optional}
%
% Output:
%  (cell)  PV : Parameter, State Projections (reduced x full)
%
% Keywords: Model Reduction, Combined Reduction, Bayesian Inversion
%
%*

warning off all 
optflag = optimset('Display','off');

if(~isa(A,'function_handle')), N = sqrt(numel(P)); A = @(p) reshape(p,[N N]); end

%Extract Dimensions
h = T(2);
t = (T(3)-T(1))/h;
N = sqrt(numel(A(P)));
J = size(B,2);
O = size(C,1);
G = numel(P);

%Fix lazy arguments
if(B==0)        B = sparse(N,J);   end
if(C==1)        C = speye(N);      end
if(D==0)        D = sparse(O,J);   end

if(nargin<9)    X = 0;             end
if(nargin<10)   U = 1;             end
if(nargin<11)   S = 1;             end
if(nargin<12)   q = [0,0,0,0,0,0,0,0]; end
if(nargin<13)   y = 0;             end

if(numel(F)==1) F = F*ones(N,1);   end
if(numel(X)==1) X = X*ones(N,1);   end
if(numel(U)==1) U = U*[ones(J,1), sparse(J,t-1)]; end
if(numel(S)==1) S = S*speye(G); end
if(numel(q)<8)  q(8) = 0; end

%Parameter Checks
%if(R>G || G<0) error('ERROR: Be serious!'); end
if(N~=size(B,1))       error('ERROR: Dimension of state and input do not agree in matrix B!');         end
if(N~=size(C,2))       error('ERROR: Dimension of state and output do not agree in matrix C!');        end
if(N~=size(F,1))       error('ERROR: Dimension of state and source do not agree in vector F!');        end
if(N~=size(X,1))       error('ERROR: Dimension of state and initial state do not agree in vector X!'); end
if(J~=size(U,1))       error('ERROR: Inputs do not match input series!');                              end
if(t~=size(U,2))       error('ERROR: Timeseries length does not match input length!');                 end
if(size(S)~=[G G]) error('ERROR: Covariance dimensions do not match parameter count!');  end


%Precision from Covariance
S(S~=0) = 1.0./S(S~=0);


%Init State Projection
V = res(ode(A(P),B,speye(N),sparse(N,J),F,h,t,X,U,q(7)),q(2));


%Init Parameter Projection
switch(q(3))
	case 0, p = P;

	case 1, p = 1.0;
end

	%Main Loop
	for I=2:R
		I;

		%apply optimization to current problem
		if(q(3)), Q = P; else, Q = 1.0; end
		OBJ = @(p) obj(Q*p,A,B,C,D,F,h,t,X,U,S,V,q(5),q(4),q(7),q(8),y);
		p = fminunc(OBJ,p,optflag);

		%append projection matrices
                if(q(2)==3), Z = ode(V'*A(Q*p)*V,V'*B,V,sparse(N,J),V'*F,h,t,V'*X,U,q(7)); else Z = 0; end
		w = res(ode(A(Q*p),B,speye(N),sparse(N,J),F,h,t,X,U,q(7))-Z,q(2));
		a = p;
		if(q(3) && I<=G), a(size(P,1),1) = 0; p(I,1) = 0; end

		if(q(6)),
			P = orth([P a]);
			V = orth([V w]);
		else,
			[P,TMP] = qr([P a],0);
			[V,TMP] = qr([V w],0);
		end;
	end

	PV = {P,V};
end

%%%%%%%% OBJECTIVE %%%%%%%%
function j = obj(p,A,B,C,D,F,h,t,X,U,S,V,L,M,O,R,Y)

	b = V'*B;
	f = V'*F;
	x = V'*X;
	c = C*V;

	y = ode(V'*A(p)*V,b,c,D,f,h,t,x,U,O);

	switch(R)
		case 0
			j = p'*S*p;
		case 1
			j = sum(abs(S*p));
		case 2
			j = sum(svds(A(p)));
	end

	if(M==0 || M==1),
		Z = ode(A(p),B,C,D,F,h,t,X,U,O);
		switch(L)
			case 0,    j = j - max(sum((Z-y).^2));

			case 1,    j = j - sum(sqrt(sum((Z-y).^2)));

			case 2,    j = j - sum(sum((Z-y).^2));

			otherwise, j = j - (sum(sum((Z-y).^L))).^(1.0/L);
		end
	end

	if(M==1 || M==2)
		switch(L)
			case 0,    j = j + max(sum((Y-y).^2));

			case 1,    j = j + sum(sqrt(sum((Y-y).^2)));

			case 2,    j = j + sum(sum((Y-y).^2));

			otherwise, j = j + (sum(sum((Y-y).^L))).^(1.0/L);
		end
	end
end

%%%%%%%% RESIDUAL %%%%%%%%
function r = res(y,q)

	switch(q)
		case 0, [U D V] = svd(y,'econ'); r = U(:,1);

		case 1, r = mean(y,2);

		case 2, r = y(:,end);

		case 3, [U D V] = svd(y,'econ'); r = U(:,1);
	end
end

%%%%%%%% INTEGRATOR %%%%%%%%
function y = ode(A,B,C,D,F,h,T,x,u,O)

	y(size(C,1),T) = 0;

	switch(O)
		case 0
			for t=1:T
				x = x + h*(A*x + B*u(:,t) + F);
				y(:,t) = C*x + D*u(:,t);
			end
		case 1
			m = 0.5*h*(A*x + B*u(:,1) + F); 
			x = x + h*(A*(m + x) + B*u(:,1) + F);
			y = C*x + D*u(:,1);
			for t=2:T
				z = 0.5*h*(A*x + B*u(:,t) + F); 
				x = x + 3.0*z - m;
				y(:,t) = C*x + D*u(:,t);
				m = z;
			end			
		case 2
			for t=1:T
				z = h*(A*x + B*u(:,t) + F);
				x = x + 0.25*z + 0.75*h*(A*(x + (2.0/3.0)*z) + B*u(:,t) + F);
				y(:,t) = C*x + D*u(:,t);
			end
		case -1
			%global CUSTOM_ODE;
			y = C*CUSTOM_ODE(@(x,u,p) A*x + B*u + F,h,T,x,u,0);
	end
end
