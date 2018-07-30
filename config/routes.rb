Rails.application.routes.draw do
  resource :fizzbuzz, only: [:show , :create]
  root to: 'fizzbuzzs#show'
end
