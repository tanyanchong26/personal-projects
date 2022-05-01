import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

test_sample = np.random.multivariate_normal([0,1], 
                                            cov = [[1, 0],[0, 1]], 
                                            size = 100)

test_sample = np.vstack((test_sample, np.array([8, -2])))

plt.scatter([i[0] for i in test_sample[:-1]], 
            [i[1] for i in test_sample[:-1]], 
            s=8, 
            color = "orange")
plt.scatter(test_sample[-1][0], test_sample[-1][1], s=8, color = "red")
plt.xlabel("Dimension 1")
plt.ylabel("Dimension 2")

x_scaffold = np.linspace(-5,10,30)
y_scaffold = np.linspace(-5,5,20)

# Scott's Rule
h = len(test_sample)**(-1/6)

# Build Meshgrid

xx,yy = np.meshgrid(x_scaffold, y_scaffold)

kde = np.zeros(xx.shape)

for i,j in enumerate(x_scaffold):
    for m,n in enumerate(y_scaffold):
        placeholder = []
        for k in test_sample:
            xi = k
            x = np.array([j, n])
            l2_norm = np.linalg.norm(xi-x)
            exp_term = -l2_norm**2/(2*h**2)
            K = 1/(2*np.pi*h**2)*np.exp(exp_term)
            placeholder.append(K)
            
        kde[m, i] = np.mean(placeholder)

plt.scatter([i[0] for i in test_sample[:-1]], 
            [i[1] for i in test_sample[:-1]], 
            s=8, 
            color = "orange")
plt.scatter(test_sample[-1][0], test_sample[-1][1], s=8, color = "red")
plt.contourf(xx,yy,kde, extend="neither", 
             levels=[i for i in np.arange(0.01, 0.16, 0.01)],
             alpha=0.3)
plt.xlabel("Dimension 1")
plt.ylabel("Dimension 2")