Shader "Custom/VRChat/DetailedNightSky"
{
    Properties
    {
        [Header(Sky Colors)]
        _SkyColorTop ("Sky Color (Top)", Color) = (0.02, 0.02, 0.08, 1)
        _SkyColorHorizon ("Sky Color (Horizon)", Color) = (0.05, 0.05, 0.15, 1)
        _HorizonBlend ("Horizon Blend", Range(0.1, 5.0)) = 2.0

        [Header(Stars)]
        _StarDensity ("Star Density", Range(100, 2000)) = 500
        _StarBrightness ("Star Brightness", Range(0, 5)) = 1.5
        _StarSize ("Star Size", Range(0.0001, 0.01)) = 0.002
        _StarTwinklePeriod ("Star Twinkle Period (seconds)", Range(60, 300)) = 180
        _StarColorVariation ("Star Color Variation", Range(0, 1)) = 0.3

        [Header(Clouds)]
        _CloudTex ("Cloud Noise Texture", 2D) = "white" {}
        _CloudDensity ("Cloud Density", Range(0, 1)) = 0.4
        _CloudSpeed ("Cloud Speed", Range(0, 0.5)) = 0.05
        _CloudScale ("Cloud Scale", Range(0.1, 10)) = 2.0
        _CloudOpacity ("Cloud Opacity", Range(0, 1)) = 0.7
        _CloudBrightness ("Cloud Brightness", Range(0, 2)) = 0.3
        _CloudSharpness ("Cloud Sharpness", Range(0.1, 5)) = 1.5

        [Header(Shooting Stars)]
        _ShootingStarInterval ("Shooting Star Interval (seconds)", Range(60, 1000)) = 600
        _ShootingStarSpeed ("Shooting Star Speed", Range(0.1, 2)) = 0.8
        _ShootingStarLength ("Shooting Star Length", Range(0.01, 0.3)) = 0.1
        _ShootingStarBrightness ("Shooting Star Brightness", Range(0, 10)) = 5

        [Header(Moon)]
        [Toggle] _EnableMoon ("Enable Moon", Float) = 1
        _MoonSize ("Moon Size", Range(0.01, 0.2)) = 0.05
        _MoonBrightness ("Moon Brightness", Range(0, 5)) = 2
        _MoonDirection ("Moon Direction", Vector) = (0.5, 0.8, 0.3, 0)
    }

    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"


            // ============================================

            // SKY GRADIENT
            float4 _SkyColorTop;
            float4 _SkyColorHorizon;
            float _HorizonBlend;

            // STARS
            float _StarDensity;
            float _StarBrightness;
            float _StarSize;
            float _StarTwinklePeriod;
            float _StarColorVariation;

            // CLOUDS
            sampler2D _CloudTex;
            float4 _CloudTex_ST;
            float _CloudDensity;
            float _CloudSpeed;
            float _CloudScale;
            float _CloudOpacity;
            float _CloudBrightness;
            float _CloudSharpness;

            // SHOOTING STARS
            float _ShootingStarInterval;
            float _ShootingStarSpeed;
            float _ShootingStarLength;
            float _ShootingStarBrightness;

            // MOON
            float _EnableMoon;
            float _MoonSize;
            float _MoonBrightness;
            float4 _MoonDirection;

            // ============================================

            struct appdata
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 viewDir : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.viewDir = normalize(v.texcoord);
                return o;
            }

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            float hash2D(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
            }

            float hash3D(float3 p)
            {
                return frac(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453123);
            }

            float3 hash3D3(float3 p)
            {
                return frac(sin(float3(
                    dot(p, float3(127.1, 311.7, 74.7)),
                    dot(p, float3(269.5, 183.3, 246.1)),
                    dot(p, float3(113.5, 271.9, 124.6))
                )) * 43758.5453123);
            }

            float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 permute(float4 x) { return mod289(((x*34.0)+1.0)*x); }
            float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

            float snoise(float3 v)
            {
                const float2 C = float2(1.0/6.0, 1.0/3.0);
                const float4 D = float4(0.0, 0.5, 1.0, 2.0);

                float3 i  = floor(v + dot(v, C.yyy));
                float3 x0 = v - i + dot(i, C.xxx);

                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);

                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - D.yyy;

                i = mod289(i);
                float4 p = permute(permute(permute(
                    i.z + float4(0.0, i1.z, i2.z, 1.0))
                    + i.y + float4(0.0, i1.y, i2.y, 1.0))
                    + i.x + float4(0.0, i1.x, i2.x, 1.0));

                float n_ = 0.142857142857;
                float3 ns = n_ * D.wyz - D.xzx;

                float4 j = p - 49.0 * floor(p * ns.z * ns.z);

                float4 x_ = floor(j * ns.z);
                float4 y_ = floor(j - 7.0 * x_);

                float4 x = x_ *ns.x + ns.yyyy;
                float4 y = y_ *ns.x + ns.yyyy;
                float4 h = 1.0 - abs(x) - abs(y);

                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);

                float4 s0 = floor(b0)*2.0 + 1.0;
                float4 s1 = floor(b1)*2.0 + 1.0;
                float4 sh = -step(h, float4(0,0,0,0));

                float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

                float3 p0 = float3(a0.xy, h.x);
                float3 p1 = float3(a0.zw, h.y);
                float3 p2 = float3(a1.xy, h.z);
                float3 p3 = float3(a1.zw, h.w);

                float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;

                float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
                m = m * m;
                return 42.0 * dot(m*m, float4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
            }

            float fbm(float3 p, int octaves)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;

                for(int i = 0; i < octaves; i++)
                {
                    value += amplitude * snoise(p * frequency);
                    frequency *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            float3 generateStars(float3 dir, float time)
            {
                float3 starColor = float3(0, 0, 0);
                float3 gridPos = dir * 100.0;
                float3 cellId = floor(gridPos);

                for(int x = -1; x <= 1; x++)
                {
                    for(int y = -1; y <= 1; y++)
                    {
                        for(int z = -1; z <= 1; z++)
                        {
                            float3 offset = float3(x, y, z);
                            float3 cell = cellId + offset;
                            float3 randomOffset = hash3D3(cell);
                            float3 starPos = cell + randomOffset;
                            float starChance = hash3D(cell);

                            if(starChance < (_StarDensity / 2000.0))
                            {
                                float3 starDir = normalize(starPos);
                                float dist = distance(dir, starDir);

                                if(dist < _StarSize)
                                {
                                    float twinkleSpeed = _StarTwinklePeriod;
                                    float twinklePhase = hash3D(cell + float3(100, 100, 100)) * 6.28318;
                                    float twinkle = sin(time / twinkleSpeed * 6.28318 + twinklePhase) * 0.5 + 0.5;
                                    twinkle = pow(twinkle, 2);

                                    float brightness = 1.0 - (dist / _StarSize);
                                    brightness = pow(brightness, 3.0);
                                    brightness *= _StarBrightness * (0.5 + twinkle * 0.5);

                                    float colorShift = hash3D(cell + float3(200, 200, 200));
                                    float3 baseColor = lerp(
                                        float3(0.8, 0.9, 1.0),
                                        float3(1.0, 0.95, 0.8),
                                        colorShift * _StarColorVariation
                                    );

                                    starColor += baseColor * brightness;
                                }
                            }
                        }
                    }
                }

                return starColor;
            }

            float3 generateShootingStar(float3 dir, float time)
            {
                float cycle = floor(time / _ShootingStarInterval);
                float cycleTime = fmod(time, _ShootingStarInterval);
                float seed = hash(cycle);
                float shootingStarDuration = 2.0;
                float shootingStarStart = seed * (_ShootingStarInterval - shootingStarDuration);

                if(cycleTime < shootingStarStart || cycleTime > shootingStarStart + shootingStarDuration)
                    return float3(0, 0, 0);

                float shootingStarProgress = (cycleTime - shootingStarStart) / shootingStarDuration;

                float3 randomDir = normalize(hash3D3(float3(cycle, cycle * 2, cycle * 3)) - 0.5);
                randomDir.y = abs(randomDir.y) * 0.5 + 0.2;
                randomDir = normalize(randomDir);

                float3 velocity = normalize(cross(randomDir, float3(0, 1, 0)));
                float3 currentPos = randomDir + velocity * shootingStarProgress * _ShootingStarSpeed;
                currentPos = normalize(currentPos);

                float dist = distance(dir, currentPos);
                float trailFade = 1.0;

                for(float i = 0; i < 10; i++)
                {
                    float trailOffset = i / 10.0 * _ShootingStarLength;
                    float3 trailPos = normalize(randomDir + velocity * (shootingStarProgress - trailOffset) * _ShootingStarSpeed);
                    float trailDist = distance(dir, trailPos);

                    if(trailDist < 0.02)
                    {
                        float brightness = (1.0 - trailDist / 0.02) * (1.0 - i / 10.0);
                        brightness *= _ShootingStarBrightness;
                        brightness *= 1.0 - shootingStarProgress;
                        return float3(1, 1, 0.9) * brightness;
                    }
                }

                return float3(0, 0, 0);
            }

            float4 generateClouds(float3 dir, float time)
            {
                if(dir.y < -0.1) return float4(0, 0, 0, 0);

                float2 uv = float2(atan2(dir.x, dir.z) / 6.28318, asin(dir.y) / 3.14159 + 0.5);
                float2 cloudUV = uv * _CloudScale;
                cloudUV.x += time * _CloudSpeed * 0.01;

                float3 samplePos = float3(cloudUV * 2.0, time * 0.002);
                float cloudNoise = fbm(samplePos, 5) * 0.5 + 0.5;

                float3 samplePos2 = float3(cloudUV * 4.0 + float2(100, 100), time * 0.003);
                float cloudDetail = fbm(samplePos2, 3) * 0.5 + 0.5;

                cloudNoise = cloudNoise * 0.7 + cloudDetail * 0.3;
                cloudNoise = pow(saturate((cloudNoise - (1.0 - _CloudDensity)) * _CloudSharpness), 2.0);

                float horizonFade = smoothstep(-0.1, 0.3, dir.y);
                cloudNoise *= horizonFade;

                float3 cloudColor = float3(0.6, 0.65, 0.8) * _CloudBrightness;

                return float4(cloudColor, cloudNoise * _CloudOpacity);
            }

            float3 generateMoon(float3 dir)
            {
                if(_EnableMoon < 0.5) return float3(0, 0, 0);

                float3 moonDir = normalize(_MoonDirection.xyz);
                float dist = distance(dir, moonDir);

                if(dist < _MoonSize)
                {
                    float moonMask = 1.0 - (dist / _MoonSize);
                    moonMask = smoothstep(0.0, 0.1, moonMask);

                    float3 moonSurface = dir * 50.0;
                    float detail = hash3D(floor(moonSurface)) * 0.3;

                    float3 moonColor = float3(1, 1, 0.95) * _MoonBrightness * (0.7 + detail);
                    return moonColor * moonMask;
                }

                if(dist < _MoonSize * 2.0)
                {
                    float glow = 1.0 - (dist - _MoonSize) / _MoonSize;
                    glow = pow(glow, 3.0) * 0.3;
                    return float3(1, 1, 0.95) * glow * _MoonBrightness;
                }

                return float3(0, 0, 0);
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 dir = normalize(i.viewDir);
                float time = _Time.y;

                float skyGradient = pow(saturate(dir.y), _HorizonBlend);
                float3 skyColor = lerp(_SkyColorHorizon.rgb, _SkyColorTop.rgb, skyGradient);

                float3 stars = generateStars(dir, time);
                skyColor += stars;

                float3 shootingStar = generateShootingStar(dir, time);
                skyColor += shootingStar;

                float3 moon = generateMoon(dir);
                skyColor += moon;

                float4 clouds = generateClouds(dir, time);
                skyColor = lerp(skyColor, clouds.rgb, clouds.a);

                return float4(skyColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack Off
}
