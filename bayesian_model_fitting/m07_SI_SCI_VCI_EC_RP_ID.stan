data {
  int<lower=1> S;
  int<lower=1> T;
  int<lower=1> idx_start[S];
  int<lower=1> idx_end[S];
  int<lower=0, upper=1> y[T];
  int<lower=1, upper=2> group[S]; // 1=Female, 2=Male

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
  vector[2]          mu_kapa;
  vector<lower=0>[2] mu_etak;
  vector<lower=0>[2] mu_etaa;
  vector<lower=0>[2] mu_oumiga;    // <<< EC 新增

  // -------- group-level SDs ----------
  vector<lower=0,upper=6>[2] sigma_gama;
  vector<lower=0,upper=6>[2] sigma_envy;
  vector<lower=0,upper=6>[2] sigma_guilt;
  vector<lower=0,upper=6>[2] sigma_lambda;
  vector<lower=0,upper=6>[2] sigma_kapa;
  vector<lower=0,upper=15>[2] sigma_etak;
  vector<lower=0,upper=15>[2] sigma_etaa;
  vector<lower=0,upper=6>[2] sigma_oumiga; // <<< EC 新增

  // -------- subject-level parameters --------
  vector<lower=0>[S] gama;
  vector<lower=0>[S] envy;
  vector<lower=0>[S] guilt;
  vector<lower=0>[S] lambda;
  vector[S]          kapa;
  vector<lower=0>[S] etak;
  vector<lower=0>[S] etaa;
  vector<lower=0>[S] oumiga;       // <<< EC 新增
}

model {
  // -------- Hyperpriors --------
  mu_gama   ~ normal(5, 3);
  mu_envy   ~ normal(5, 3);
  mu_guilt  ~ normal(5, 3);
  mu_lambda ~ normal(10, 5);
  mu_kapa   ~ normal(0, 5);
  mu_etak   ~ normal(5, 3);
  mu_etaa   ~ normal(5, 3);
  mu_oumiga ~ normal(5, 3);        // <<< EC 新增

  //sigma_gama   ~ normal(0, 2);
  //sigma_envy   ~ normal(0, 2);
  //sigma_guilt  ~ normal(0, 2);
  //sigma_lambda ~ normal(0, 5);
  //sigma_kapa   ~ normal(0, 2);
  //sigma_etak   ~ normal(0, 2);
  //sigma_etaa   ~ normal(0, 2);
  //sigma_oumiga ~ normal(0, 2);     // <<< EC 新增

  // -------- Subject-level priors --------
  for (s in 1:S) {
    int g = group[s];
    gama[s]   ~ normal(mu_gama[g],   sigma_gama[g]);
    envy[s]   ~ normal(mu_envy[g],   sigma_envy[g]);
    guilt[s]  ~ normal(mu_guilt[g],  sigma_guilt[g]);
    lambda[s] ~ normal(mu_lambda[g], sigma_lambda[g]);
    kapa[s]   ~ normal(mu_kapa[g],   sigma_kapa[g]);
    etak[s]   ~ normal(mu_etak[g],   sigma_etak[g]);
    etaa[s]   ~ normal(mu_etaa[g],   sigma_etaa[g]);
    oumiga[s] ~ normal(mu_oumiga[g], sigma_oumiga[g]); // <<< EC 新增
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
      real RP    = fmax(x2s - x1s, 0);

      // ID attention
      real IIk = 2 / (1 + exp(etak[s] * (c / 5)));
      real IIa = 2 / (1 + exp(etaa[s] * (c / 5)));

      // EC terms
      real EP_yes = x1s + x2s;
      real EP_no  = x1  + x2;

      real Uyes = x3s
                  - envy[s]  * disad
                  - guilt[s] * ad
                  - gama[s]  * inqua * IIa
                  + kapa[s]  * RP
                  + oumiga[s] * EP_yes;   // <<< EC 新增

      real Uno  = x3
                  - envy[s]  * (fmax(x1 - x3,0) + fmax(x2 - x3,0))
                  - guilt[s] * (fmax(x3 - x1,0) + fmax(x3 - x2,0))
                  - gama[s]  * (fmax(x1 - x2,0) * IIk)
                  + kapa[s]  * fmax(x2 - x1,0)
                  + oumiga[s] * EP_no;    // <<< EC 新增

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
      real RP    = fmax(x2s - x1s, 0);

      real IIk = 2 / (1 + exp(etak[s] * (c / 5)));
      real IIa = 2 / (1 + exp(etaa[s] * (c / 5)));

      real EP_yes = x1s + x2s;
      real EP_no  = x1  + x2;

      real Uyes = x3s
                  - envy[s]*disad
                  - guilt[s]*ad
                  - gama[s]*inqua*IIa
                  + kapa[s]*RP
                  + oumiga[s]*EP_yes;

      real Uno  = x3
                  - envy[s]*(fmax(x1 - x3,0)+fmax(x2 - x3,0))
                  - guilt[s]*(fmax(x3 - x1,0)+fmax(x3 - x2,0))
                  - gama[s]*(fmax(x1 - x2,0)*IIk)
                  + kapa[s]*fmax(x2 - x1,0)
                  + oumiga[s]*EP_no;

      real p = inv_logit(lambda[s] * (Uyes - Uno));
      ll += bernoulli_lpmf(y[t] | p);
    }
    log_lik_subj[s] = ll;
  }
}
