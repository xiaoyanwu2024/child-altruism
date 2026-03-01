data {
  int<lower=1> S;                 // subjects
  int<lower=1> T;                 // total trials
  int<lower=1> idx_start[S];
  int<lower=1> idx_end[S];
  int<lower=0, upper=1> y[T];     // action (0/1)
  int<lower=1, upper=2> group[S]; // 1=Female, 2=Male
}

parameters {
  // -------- group-level means (logit scale) --------
  vector[2] mu_logit_p;

  // -------- group-level SDs --------
  vector<lower=0>[2] sigma_logit_p;

  // -------- subject-level parameters (logit scale) --------
  vector[S] logit_p;
}

model {
  // -------- Hyperpriors --------
  mu_logit_p     ~ normal(0, 2);   // weakly informative, centered at p=0.5
  sigma_logit_p  ~ normal(0, 1);

  // -------- Subject-level priors --------
  for (s in 1:S) {
    int g = group[s];
    logit_p[s] ~ normal(mu_logit_p[g], sigma_logit_p[g]);
  }

  // -------- Likelihood --------
  for (s in 1:S) {
    real p = inv_logit(logit_p[s]);
    for (t in idx_start[s]:idx_end[s]) {
      y[t] ~ bernoulli(p);
    }
  }
}

generated quantities {
  vector[S] log_lik_subj;
  vector[S] p_subj;

  for (s in 1:S) {
    real ll = 0;
    real p  = inv_logit(logit_p[s]);
    p_subj[s] = p;

    for (t in idx_start[s]:idx_end[s]) {
      ll += bernoulli_lpmf(y[t] | p);
    }
    log_lik_subj[s] = ll;
  }
}