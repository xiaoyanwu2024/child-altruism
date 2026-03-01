data {
  int<lower=1> S;                 // subjects
  int<lower=1> T;                 // total trials
  int<lower=1> idx_start[S];
  int<lower=1> idx_end[S];
  int<lower=0, upper=1> y[T];     // action (0/1)
  int<lower=1, upper=2> group[S]; // 1=Female, 2=Male

  // trial-level variable
  real cost[T];
}

parameters {
  // -------- group-level means --------
  vector<lower=0>[2] mu_lambda;

  // -------- group-level SDs ----------
  vector<lower=0>[2] sigma_lambda;

  // -------- subject-level parameters --------
  vector<lower=0>[S] lambda;
}

model {
  // -------- Hyperpriors (same family as all other models) --------
  mu_lambda ~ normal(10, 5);
  sigma_lambda ~ normal(0, 5);

  // -------- Subject-level priors --------
  for (s in 1:S) {
    int g = group[s];
    lambda[s] ~ normal(mu_lambda[g], sigma_lambda[g]);
  }

  // -------- Likelihood --------
  for (s in 1:S) {
    for (t in idx_start[s]:idx_end[s]) {

      real x3 = 5;
      real c  = cost[t];

      real Uyes = x3 - c;
      real Uno  = x3;

      real p = inv_logit(lambda[s] * (Uyes - Uno));
      y[t] ~ bernoulli(p);
    }
  }
}

generated quantities {
  vector[S] log_lik_subj;

  for (s in 1:S) {
    real ll = 0;
    for (t in idx_start[s]:idx_end[s]) {

      real x3 = 5;
      real c  = cost[t];

      real Uyes = x3 - c;
      real Uno  = x3;

      real p = inv_logit(lambda[s] * (Uyes - Uno));
      ll += bernoulli_lpmf(y[t] | p);
    }
    log_lik_subj[s] = ll;
  }
}