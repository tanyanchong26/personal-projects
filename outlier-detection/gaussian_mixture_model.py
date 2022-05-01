from sklearn.datasets import make_blobs
import matplotlib.pyplot as plt
import numpy as np

#%% Method 1 - Kernel Denstiy Estimate

data, cluster = make_blobs(n_samples=400, 
                           centers=3, 
                           cluster_std=0.6, 
                           random_state=1)

cluster_mod = np.append(cluster, 3)
cluster_mod = np.append(cluster_mod, 3)
cluster_mod = np.append(cluster_mod, 3)

data_mod = np.vstack((data, [-6, -4]))
data_mod = np.vstack((data_mod, [-10,-8]))
data_mod = np.vstack((data_mod, [-2.5,-2.5]))


plt.scatter(data[:,0], data[:,1], s=5, c= cluster)
plt.scatter(-6, -4, marker="x", color="b")
plt.scatter(-10, -8, marker="x", color="b")
plt.scatter(-2.5, -2.5, marker="x", color="b")
plt.xlabel("x")
plt.ylabel("y")

x_scaffold = np.linspace(-15,5,40)
y_scaffold = np.linspace(-12,8,40)

# Scott's Rule
h = len(data_mod)**(-1/6)

# Build Meshgrid

xx,yy = np.meshgrid(x_scaffold, y_scaffold)

kde = np.zeros(xx.shape)

for i,j in enumerate(x_scaffold):
    for m,n in enumerate(y_scaffold):
        placeholder = []
        for k in data_mod:
            xi = k
            x = np.array([j, n])
            l2_norm = np.linalg.norm(xi-x)
            exp_term = -l2_norm**2/(2*h**2)
            K = 1/(2*np.pi*h**2)*np.exp(exp_term)
            placeholder.append(K)
            
        kde[m, i] = np.mean(placeholder)

plt.scatter(data_mod[:,0], data_mod[:,1], s=7, c= cluster_mod)
plt.contourf(xx,yy,kde, extend="neither", 
             levels=[i for i in np.arange(0.01, 0.14, 0.005)],
             alpha=0.3)
plt.xlabel("x")
plt.ylabel("y")

#%% Method 2 - Gaussian Mixture Model

from sklearn.mixture import GaussianMixture

gm = GaussianMixture(n_components = 3, covariance_type = 'full',
                     init_params = "kmeans", max_iter=1000)
gm.fit(data)

#%% Plot the Fitted GMM

def gmm_fitted(x, gm):
    
    means = gm.means_
    covariances = gm.covariances_
    weights = gm.weights_
    
    values = []
    
    for i,j in enumerate(weights):
        values.append(1/np.sqrt(np.linalg.det(covariances[i]))/(2*\
                      np.pi)*np.exp(-0.5*(x-means[i]).T \
                                   @ np.linalg.inv(covariances[i]) \
                                       @ (x-means[i])))
    
    return np.sum(values*weights)

gmm_matrix = np.zeros(xx.shape)

for i,j in enumerate(x_scaffold):
    for m,n in enumerate(y_scaffold):
        x = np.array([j, n])
        gmm_matrix[m, i] = gmm_fitted(x,gm)

fig = plt.figure()
ax = plt.axes(projection = "3d")
surf = ax.contour3D(xx, yy, gmm_matrix, 200)
fig.colorbar(surf, shrink=0.5, aspect=10, ax=ax)
ax.scatter3D(data[:,0], data[:,1], [0]*len(data))
ax.figure.set_size_inches(20, 10)
ax.set_xlabel('x')
ax.set_ylabel('y')
ax.set_zlabel('Density')
ax.view_init(60, 60)

#%% Outlier Detection

proba = gm.predict_proba(data_mod)
clusters_pred = np.argmax(proba, axis = 1)

plt.scatter(data_mod[:,0], data_mod[:,1], s=5, c= clusters_pred)

exclusion_proba = []

for i in proba:
    exclusion_proba.append(1 - np.multiply.reduce(1 - i))
    
cm = plt.cm.get_cmap('binary')
plt.scatter(data_mod[:,0], data_mod[:,1], s=5, c= exclusion_proba)
plt.colorbar()
