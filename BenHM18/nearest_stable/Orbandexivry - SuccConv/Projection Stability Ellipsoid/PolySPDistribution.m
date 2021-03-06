function [b0] = PolySPDistribution(A,e_lon,isdiscrete)
%[b0] = PolySPDistribution(A,e_lon,isdiscrete) creates a stable polynomial
%b0 whose roots keep the same distribution as the unstable polynomial. In
%continuous time, this is equivalent to a shift of the roots. In discrete
%time, this is equivalent to a contraction.
%
%The computation of the roots is achieved using the matlab method "root".
%
%
%Input : A         : a companion matrix representing a polynomial.
%        e_lon     : a scalar that gives a distance to stability so that b0
%                    is not too close to the boundary
%        isdiscrete: 1 if the problem is discrete, 0 otherwise.
%
%History : 04/07/2011 : Creation
%Last modified : 04/07/2011

%% Preprocessing

%parameter : default_dist specifies the distance at which the most right-
%(in continuous time) or the max-magnitude- (in discrete time) root should
%be from the stability boundary
default_dist = 0.05;

%vector of coefficients of the polynomial
a = poly(A);


%% Processing

%computing the roots of the polynomial in O(n^3) operations
allroots = roots(a);

if ~isdiscrete

    %finding the roots that are unstable
    rightmost = max(real(allroots));

    %if the rightmost eigenvalue is not stable
    if rightmost > 0+e_lon - eps %marginaly stable roots are included

        %the correction is computed
        corr = rightmost -e_lon +eps + default_dist;

        %shifting the roots to the left half-plane
        allroots = allroots - corr;
    end

else
    if (1-default_dist) < eps || default_dist<0
        error('The parameter default_dist has been set to a value negative or greater or equal to one in PolySPDistribution')
    end
    maxmodul = max(abs(allroots));
    %finding the roots that are unstable
    if maxmodul > 1+e_lon-eps %marginally stable roots are included

        %computing the correction
        corr = (1+e_lon-default_dist)/maxmodul;

        %contracting the roots inside the unit circle
        allroots = allroots*corr;

    end
end

%reconstructing a stable polynomial
b0 = poly(allroots);
b0 = fliplr(b0(2:end)).';
