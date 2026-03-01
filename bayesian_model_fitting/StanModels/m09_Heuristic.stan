data {
  int<lower=1> S;                 // subjects
  int<lower=1> T;                 // total trials
  int<lower=1> idx_start[S];
  int<lower=1> idx_end[S];
  int<lower=0, upper=1> y[T];     // action (0/1)
  int<lower=1, upper=2> group[S]; // 1=Female, 2=Male

  // trial-level variables
  int<lower=1, upper=2> block[T]; // 1=punish, 2=help
  real violator[T];
  real victim[T];
  real cost[T];
  real ratio[T];
}

parameters {
  // -------- group-level means --------
  vector<lower=0>[2] mu_lambda;
  vector[2]          mu_bs;
  vector[2]          mu_bi;
  vector[2]          mu_bc;
  vector[2]          mu_br;

  // -------- group-level SDs ----------
  vector<lower=0>[2] sigma_lambda;
  vector<lower=0>[2] sigma_bs;
  vector<lower=0>[2] sigma_bi;
  vector<lower=0>[2] sigma_bc;
  vector<lower=0>[2] sigma_br;

  // -------- subject-level parameters --------
  vector<lower=0>[S] lambda;
  vector[S]          bs;
  vector[S]          bi;
  vector[S]          bc;
  vector[S]          br;
}

model {
  // -------- Hyperpriors (same family as other models) --------
  mu_lambda ~ normal(10, 5);
  mu_bs     ~ normal(0, 5);
  mu_bi     ~ normal(0, 5);
  mu_bc     ~ normal(0, 5);
  mu_br     ~ normal(0, 5);

  sigma_lambda ~ normal(0, 5);
  sigma_bs     ~ normal(0, 2);
  sigma_bi     ~ normal(0, 2);
  sigma_bc     ~ normal(0, 2);
  sigma_br     ~ normal(0, 2);

  // -------- Subject-level priors --------
  for (s in 1:S) {
    int g = group[s];
    lambda[s] ~ normal(mu_lambda[g], sigma_lambda[g]);
    bs[s]     ~ normal(mu_bs[g],     sigma_bs[g]);
    bi[s]     ~ normal(mu_bi[g],     sigma_bi[g]);
    bc[s]     ~ normal(mu_bc[g],     sigma_bc[g]);
    br[s]     ~ normal(mu_br[g],     sigma_br[g]);
  }

  // -------- Likelihood --------
  for (s in 1:S) {
    for (t in idx_start[s]:idx_end[s]) {

      // recode block: punish = +1, help = -1
      real block_sgn = (block[t] == 1) ? 1 : -1;

      real inequa = fmax(violator[t] - victim[t], 0);

      real lin = bs[s] * block_sgn
               + bi[s] * inequa
               + bc[s] * cost[t]
               + br[s] * ratio[t];

      real p = inv_logit(-lambda[s] * lin);

      y[t] ~ bernoulli(p);
    }
  }
}

generated quantities {
  vector[S] log_lik_subj;

  for (s in 1:S) {
    real ll = 0;
    for (t in idx_start[s]:idx_end[s]) {

      real block_sgn = (block[t] == 1) ? 1 : -1;
      real inequa = fmax(violator[t] - victim[t], 0);

      real lin = bs[s] * block_sgn
               + bi[s] * inequa
               + bc[s] * cost[t]
               + br[s] * ratio[t];

      real p = inv_logit(-lambda[s] * lin);

      ll += bernoulli_lpmf(y[t] | p);
    }
    log_lik_subj[s] = ll;
  }
}