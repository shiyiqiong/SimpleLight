版本：Unity 2022.3.14f1c1。
***
传统经验光照模型：
- Lambert（兰伯特光照模型）；
- HalfLambert(半兰伯特光照模型)；
- Phong（冯氏光照模型）；
- BlinnPhong（布林冯氏光照模型）。
***
- 漫反射模型：计算光照漫反射强度，光照向量投射到法线向量。
  
  ![image](https://github.com/user-attachments/assets/b5ac26ed-1ed0-44d9-a453-e16fc69459f8)
  
- 镜面反射模型（Phong）：计算镜面反射强度，光源反射向量投射到视角向量。
  
  ![image](https://github.com/user-attachments/assets/65df697a-6424-487a-b16d-28f2979dd53c)

- 镜面反射模型（BlinnPhong）：计算镜面反射强度，半程向量（光照向量+视角向量，取归一化）投射到法线向量。

  ![image](https://github.com/user-attachments/assets/a9bba307-d091-4356-a7d6-608552f4e440)

***
参考资料：https://gwb.tencent.com/community/detail/125165
