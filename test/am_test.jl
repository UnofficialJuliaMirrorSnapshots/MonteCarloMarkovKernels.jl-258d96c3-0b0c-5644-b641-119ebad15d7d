using MonteCarloMarkovKernels
using StaticArrays
import Statistics.mean
using Random
using Test

function makelogMVN(μ::SVector{d, Float64}, Σ::SMatrix{d, d, Float64}) where d
  invΣ = inv(Σ)
  lognc = - 0.5 * d * log(2 * π) - 0.5 * logdet(Σ)
  function lpi(x::SVector{d, Float64})
    v = x - μ
    return lognc - 0.5*dot(v, invΣ * v)
  end
  return lpi
end

function testd(d::Int64)
  zerod = zeros(d)
  Szerod = SVector{d, Float64}(zerod)
  μ = randn(d)
  A = randn(d, d)
  Σ = A * A'

  logtarget = makelogMVN(SVector{d, Float64}(μ), SMatrix{d, d, Float64}(Σ))

  P_AM = makeAMKernel(logtarget, d, Random.GLOBAL_RNG, d^2)
  chain = simulateChainProgress(P_AM, Szerod, d*2^21)

  @test maximum(abs.(mean(chain) - μ)) < 0.1
  @test maximum(abs.(MonteCarloMarkovKernels.cov(chain) - Σ)) < 0.1

  @test 0.234 < P_AM(:acceptanceRate) < 0.45
  @test P_AM(:meanEstimate) ≈ mean(chain) atol=0.01
  @test maximum(abs.(MonteCarloMarkovKernels.cov(chain) - P_AM(:covEstimate))) < 0.01

end

seed!(12345)

for d in 1:3
  testd(d)
end

## test that only custom RNG is used
Szero2 = SVector{2, Float64}(zeros(2))
μ = randn(2)
A = randn(2, 2)
Σ = A * A'
logtarget = makelogMVN(SVector{2, Float64}(μ), SMatrix{2, 2, Float64}(Σ))
P_AM = makeAMKernel(logtarget, 2, MersenneTwister(54321))
Random.seed!(1); v1 = rand(); Random.seed!(1)
chain = simulateChain(P_AM, Szero2, 2^13)
v2 = rand()
@test v1 == v2
