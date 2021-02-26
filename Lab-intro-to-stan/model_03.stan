data {
  int<lower=0> n; // size of trainging set (with NAs)
  int<lower=0> n_o2; // number of observations
  int o2_x[n_o2];
  real o2_y[n_o2];
  real o2_z[n_o2];  
  real o2_sd[n_o2];
  int<lower=0> n_temp; // number of observations
  int temp_x[n_temp];
  real temp_y[n_temp];
  real temp_sd[n_temp];  
  int n_forecast;
  int n_lag_o2;
  int n_lag_temp;
}
transformed data {
  vector[2] zeros;
  matrix[2,2] identity;
  int lag_o2;
  int lag_temp;  
  zeros = rep_vector(0, 2);
  identity = diag_matrix(rep_vector(1.0,2));

  lag_o2 = 1;
  lag_temp = 1;
  if(n_lag_o2 > 1) lag_o2 = 1;
  if(n_lag_temp > 1) lag_temp = 1;  
}
parameters {
  vector[2] devs[n+n_forecast-1];
  cov_matrix[2] Sigma;
  matrix[2,2] ma_coefs;
  //real<lower=2> nu;
  real o2_depth; // o2 effect in observation model
  real o2_x0[lag_o2]; // initial conditions
  real temp_x0[lag_temp]; // initial conditions
  real<lower=-2,upper=2> o2_b[lag_o2];
  real<lower=-2,upper=2> temp_b[lag_temp]; 
  real<lower=-2,upper=2> temp_on_o2_b[lag_o2];
  real<lower=-2,upper=2> o2_on_temp_b[lag_temp]; 
  real u_temp;
  real u_o2;
}
transformed parameters {
  vector[n+n_forecast] o2_pred;
  vector[n_forecast] o2_forecast;
  vector[n+n_forecast] temp_pred;
  vector[n_forecast] temp_forecast;  

  // predictions for first states
  for(t in 1:lag_o2) {
    o2_pred[t] = o2_x0[t];
  }
  for(t in 1:lag_o2) {
    temp_pred[t] = temp_x0[t];
  }  

  for(i in (1+lag_o2):(n+n_forecast)) {
    o2_pred[i] = u_o2;
    if(n_lag_o2 > 0) {
      for(k in 1:lag_o2) {
        o2_pred[i] += o2_b[k]*o2_pred[i-k];// + temp_on_o2_b[k]*temp_pred[i-k];
      }
    } else {
      o2_pred[i] += o2_pred[i-1];
    }
    o2_pred[i] += devs[i-1,1];
  }
  for(i in (1+lag_temp):(n+n_forecast)) {
    temp_pred[i] = u_temp;
    if(n_lag_temp > 0) {
      for(k in 1:n_lag_temp) {
        temp_pred[i] += temp_b[k]*temp_pred[i-k];// + o2_on_temp_b[k]*o2_pred[i-k];
      }
    } else {
      temp_pred[i] = temp_pred[i-1]; 
    }
    temp_pred[i] += devs[i-1,2];
  }

  // this is redundant but easier to work with output -- creates object o2_forecast
  // containing forecast n_forecast time steps ahead
  for(t in 1:n_forecast) {
    o2_forecast[t] = o2_pred[n_o2+t];
    temp_forecast[t] = temp_pred[n_temp+t];
  }
    
}
model {
  // initial conditions, centered on mean
  o2_x0 ~ normal(7,3);
  temp_x0 ~ normal(22,3);

  // AR coefficients
  o2_b ~ normal(1,1);
  temp_b ~ normal(1,1);
  // coefficients on eachother
  temp_on_o2_b ~ normal(0,1);
  o2_on_temp_b ~ normal(0,1);  
  // optional
  o2_depth ~ normal(0,1);
  // df parameter
  //nu ~ student_t(3,2,2);
  devs[1] ~ multi_student_t(3, zeros, Sigma);
  for(i in 2:(n+n_forecast-1)) {
    devs[i] ~ multi_student_t(3, ma_coefs*devs[i-1], Sigma);
    //devs[i] ~ multi_student_t(nu, zeros, Sigma);
  }

  // likelihood
  for(t in 1:n_o2) {
    o2_y[t] ~ normal(o2_pred[o2_x[t]], o2_sd[t]);
  }
  for(t in 1:n_temp) {
    temp_y[t] ~ normal(temp_pred[temp_x[t]], temp_sd[t]);
  }
} 
generated quantities {
  
}

