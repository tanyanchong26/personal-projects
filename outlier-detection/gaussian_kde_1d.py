import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

test_sample = list(np.random.normal(0, 1, size = 100))
test_sample.append(10)

x = [i for i in range(-15,15)]

### Silverman's Rule of Thumb

h = 1.06 * np.std(x) * len(test_sample)**(-0.2)

### Execute KDE

kde = []

for i in x:
    placeholder = []
    for j in test_sample:
        u = (j - i)/h
        K = 1/(np.sqrt(2*np.pi)*h)*np.exp(-u**2/2)
        placeholder.append(K)
    kde.append(np.mean(placeholder))

threshold = (np.max(kde) - np.min(kde))*0.1+np.min(kde)

plt.plot(x, kde)
plt.scatter(test_sample, 
            [0 for i in enumerate(test_sample)], 
            s=1.2)
plt.hlines(threshold, 
           color="red", 
           xmin=-15, 
           xmax=15)
plt.xlabel("x")
plt.ylabel("Density")
