data {
  int<lower=1> S;                 // subjects
  int<lower=1> T;                 // total trials
  int<lower=1> idx_start[S];
  int<lower=1> idx_end[S];
  int<lower=0, upper=1> y[T];     // action (0/1)
  int<lower=1, upper=2> group[S]; // 1=Female, 2=Male

  // trial-level variables
  int<lower=1, upper=2> block[T]; // 1=punishment, 2=help
  real violator[T];
  real victim[T];
  real cost[T];
  real ratio[T];
}

parameters {
  // -------- group-level means --------
  vector<lower=0>[2] mu_gama;
  vector<lower=0>[2] mu_envy;
  vector<lower=0>[2] mu_guilt;
  vector<lower=0>[2] mu_lambda;

  // -------- group-level SDs ----------
  vector<lower=0>[2] sigma_gama;
  vector<lower=0>[2] sigma_envy;
  vector<lower=0>[2] sigma_guilt;
  vector<lower=0>[2] sigma_lambda;

  // -------- subject-level parameters --------
  vector<lower=0>[S] gama;
  vector<lower=0>[S] envy;
  vector<lower=0>[S] guilt;
  vector<lower=0>[S] lambda;
}

model {
  // -------- Hyperpriors (same family as other models) --------
  mu_gama   ~ normal(5, 3);
  mu_envy   ~ normal(5, 3);
  mu_guilt  ~ normal(5, 3);
  mu_lambda ~ normal(10, 5);

  sigma_gama   ~ normal(0, 2);
  sigma_envy   ~ normal(0, 2);
  sigma_guilt  ~ normal(0, 2);
  sigma_lambda ~ normal(0, 5);

  // -------- Subject-level priors --------
  for (s in 1:S) {
    int g = group[s];
    gama[s]   ~ normal(mu_gama[g],   sigma_gama[g]);
    envy[s]   ~ normal(mu_envy[g],   sigma_envy[g]);
    guilt[s]  ~ normal(mu_guilt[g],  sigma_guilt[g]);
    lambda[s] ~ normal(mu_lambda[g], sigma_lambda[g]);
  }

  // -------- Likelihood --------
  for (s in 1:S) {
    for (t in idx_start[s]:idx_end[s]) {

      real x1 = violator[t];
      real x2 = victim[t];
      real x3 = 5;
      real c  = cost[t];
      real r  = ratio[t];
      int  b  = block[t];

      real x3s;
      real x1s;
      real x2s;

      // payoff transformation
      x3s = x3 - c;
      if (b == 1) {
        x1s = x1 - c * r;
        x2s = x2;
      } else {
        x1s = x1;
        x2s = x2 + r * c;
      }

      // inequality terms
      real disad = fmax(x1s - x3s, 0) + fmax(x2s - x3s, 0);
      real ad    = fmax(x3s - x1s, 0) + fmax(x3s - x2s, 0);
      real inqua = fmax(x1s - x2s, 0);

      // utilities
      real Uyes = x3s
                  - envy[s]  * disad
                  - guilt[s] * ad
                  - gama[s]  * inqua;

      real Uno  = x3
                  - envy[s]  * (fmax(x1 - x3,0) + fmax(x2 - x3,0))
                  - guilt[s] * (fmax(x3 - x1,0) + fmax(x3 - x2,0))
                  - gama[s]  * fmax(x1 - x2,0);

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

      real x1 = violator[t];
      real x2 = victim[t];
      real x3 = 5;
      real c  = cost[t];
      real r  = ratio[t];
      int  b  = block[t];

      real x3s;
      real x1s;
      real x2s;

      x3s = x3 - c;
      if (b == 1) {
        x1s = x1 - c * r;
        x2s = x2;
      } else {
        x1s = x1;
        x2s = x2 + r * c;
      }

      real disad = fmax(x1s - x3s, 0) + fmax(x2s - x3s, 0);
      real ad    = fmax(x3s - x1s, 0) + fmax(x3s - x2s, 0);
      real inqua = fmax(x1s - x2s, 0);

      real Uyes = x3s
                  - envy[s]*disad
                  - guilt[s]*ad
                  - gama[s]*inqua;

      real Uno  = x3
                  - envy[s]*(fmax(x1 - x3,0)+fmax(x2 - x3,0))
                  - guilt[s]*(fmax(x3 - x1,0)+fmax(x3 - x2,0))
                  - gama[s]*fmax(x1 - x2,0);

      real p = inv_logit(lambda[s] * (Uyes - Uno));
      ll += bernoulli_lpmf(y[t] | p);
    }
    log_lik_subj[s] = ll;
  }
}