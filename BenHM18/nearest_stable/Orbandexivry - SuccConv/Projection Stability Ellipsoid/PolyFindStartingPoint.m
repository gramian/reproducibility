function [b0] = PolyFindStartingPoint(A,e_lon,isdiscrete,S)
% [b0] = PolyFindStartingPoint(A) determines an acceptable starting point
% for StablePolyMain. The method factorizes the characteristic polynomial
% of A in two polynomials p1 and p2. The first one (p1) contains  the roots
% contained in the complex unit disk (that are stable) and the second one
% (p2) contains the roots outside the unit disk (that are instable). A
% stable polynomial is built by mirroring p2 and multiply the two
% polynomials, i.e: b0 = p1 * (-p2) (multiplication of polynomials is
% convolution of vectors).
% This method can be directly used for the discrete case, but also work for
% the continuous case where the half plane is taken as a circle through an
% arithmetic trick.
% The method is based on the paper "Fast Fourier methods in computational
% analysis", Siam 1979.
%
% Input : A         : A companion matrix or a vector containing the last
%                     column of the companion matrix.
%         e_lon     : The margin for the stable region (see StablePolyMain)
%         isdiscrete: 1 if discrete case, 0 otherwise
%         S         : User supplied starting point, S should be a vector of
%                     coefficients of a monic polynomial ordered by
%                     ascending power. S should be of length n (so that it
%                     does not contain the coefficient 1 of x^{n+1}).
%
% Output : b0       : A vector of length n containing the n unknown
%                     coefficients of a monic polynomial of order n. The
%                     roots of b0 are the stable roots of A, and the
%                     mirrored(opposite or inverse depending on the case)
%                     unstable roots of A.
%
% Created  : 25/09/2010
%
% Modified : 4/11/2010 : the starting point is determined by factorization
% of the characteristic polynomial of A.
%
% Modified : 6/11/2010 : Incorporated the transformation for dealing with
%                        polynomials representing continuous time systems.
%
% Last modification : 06/12/2010

% if nargin == 0
%     A = [1.5 0.9999 1+i -0.5-0.8i 0.001 -0.5 0.5 100];
%     e_lon = 0;
%     isdiscrete = 0;
%     S = [];
% end

if nargin == 1
    e_lon = 0;
    isdiscrete = 0;
    S = [];
end


% if ~isdiscrete
%     n = size(A,1);
%     %the roots of the starting points are -1.
%     %so pol is x+1 (matlab takes decreasing powers)
%     pol = [1 1];
%     b0 = pol;
%
%     %if we have n coefficients, the polynomial is of order n and we have
%     %n+1 coefficients to create. The number of iteration for reaching a polynomial of length l is given
%     %by n+1 = 2^k+1 thus
%     nk = floor(log2(n));
%     for k =1:nk
%         b0 = conv(b0,b0);
%     end
%     %since log2(n) is not necessarily an integer, we convolute with pol
%     %until we reach the desired length l
%     for k=1:(n+1-(2^nk+1))
%         b0 = conv(b0,pol);
%     end
%
%     %putting bi in reverse order and deleting the first coefficient
%     %(norming the vector is unnecessary since we know it is 1)
%     b0 = b0(n+1:-1:2).';
%     return
% end

Henrici = 0;
Reflection = 0;
Mirrored = 1;
Distribution = 0;
Fixed = 0;

if isdiscrete && ((e_lon+1)<eps)
    error('The parameter e_lon is too small, it is not possible to find a starting point in the discrete case')
end

if ~isempty(S)
    na = size(A);
    ns= size(S);
    
    if any(na-ns)
        error('The size of the argument ''s'' is not the same as ''a''. Wrong size of startingpoint in PolyFindStartingPoint')
    end
    b0 = S(:,ns(2));

elseif Henrici
    b0 = PolySPHenrici(A,e_lon,isdiscrete);
elseif Reflection
    %for testpolymoses:the value of coef is =0.001
    %for ordinary test (benelux meeting/marrakech : coef is 1
    coeff = 1;
    b0 = PolySPReflection(A,e_lon,isdiscrete,coeff);
elseif Mirrored
    b0 = PolySPMirrored(A,e_lon,isdiscrete);
elseif Distribution
    b0 = PolySPDistribution(A,e_lon,isdiscrete);
elseif Fixed
    r = eig(A);
    n= length(r);
    b = poly( [(-0.9)*ones(n,1)]);
    b0 = flipud(b(2:end).');
else
    error('Please activate one starting point algorithm')
end
end

