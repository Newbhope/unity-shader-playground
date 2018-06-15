Shader "Custom/GeomShader"
{
	Properties
	{
		// Essentially public variable definitions
		// Notice no semicolons
		// Extra braces are artifact from old way of doing things --> compiler expects them

		// Text lines are painted - they dont usually come from shader
		// These strings are the display names for these properties
		
		_Texture ("Texture", 2D) = "white" {}

		// I don't know how to get these in to the inital vertex shader call
		_DeltaAngle ("DeltaAngle", Float) = 15.0
		_BranchLength ("BranchLength", Float) = 5.0
		_MaxDepth("MaxDepth", Float) = 3.0

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Off

		Pass
		{
			// Declaring C for Graphics program
			CGPROGRAM

			// Declaring functions
			#pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
			
			#include "UnityCG.cginc"

			// Getting properties into subshader
			sampler2D _Texture;
			float4 _Texture_ST;
			float _DeltaAngle;
			float _BranchLength;
			float _MaxDepth;

			// Struct to hold what is passed into vertex shader
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct geometryOutput
			{
				// This represents a screen position, as opposed to the other POSITIONS that represent world positions
				// This is why the surface extrustion shader does the transform in the geometry shader
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct geometryInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			// Arguments stored in stack for recursively rendering tree points
			struct branchArgs
			{
				geometryOutput lastVertex;
				float lastX;
				float lastY;
			    float len;
			    float angle;
			    float depth;
			};

			// Can't recurse in GLSL shaders
			// Need a stack to store branch-generating arguments
			struct stack
			{
			    branchArgs stk[1000];
			    int top;
			};

			stack argStack;

			// Slap a new set of branch arguements on the stack
			void push (branchArgs ba)
			{
			    if (argStack.top == (999))
			    {
			        return;
			    }
			    else
			    {
			        ++argStack.top;
			        argStack.stk[argStack.top] = ba;
			    }
			}

			// Function to grab next item in stack
			// Top tracked with int
			branchArgs pop ()
			{
				float4 nullVertex = float4(0., 0., 0., 1.);
				float2 nullUV = float2(1., 1.);
				struct geometryOutput g = {nullVertex, nullUV};
				struct branchArgs ba = {g, 0., 0., 0., 0., 0.};
			    if (argStack.top == -1)
			    {
			        return ba;
			    }
			    else
			    {
			        ba = argStack.stk[argStack.top];
			        --argStack.top;
			    }
			    return ba;
			}

			// Vertex shader function
			geometryInput vert (appdata_base v)
			{
				geometryInput o;

				// Translates from local space to clip space
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _Texture);

				return o;
			}

			// Using triangles here because unity's default mesh topology is triangles
			// NOTES ON PIPELINE
				// You must set every value in your g2f immediately before you append it
				// It seems like you don't have to call the input array immediately before. Or ever. 
			// Tree will face screen always because world-space to screen-space is called in the vertex shader
			[maxvertexcount(152)]
			void geom(triangle geometryInput p[3], inout TriangleStream<geometryOutput> triStream) 
			{

				float4 firstVertex = p[0].vertex;
				float2 firstUV = p[0].uv;
				float z = p[0].vertex.z;

				// If the points dont have the base points w, then only one branch was spawning
				float w = p[0].vertex.w;

				struct geometryOutput firstG2F = {firstVertex, firstUV};
				struct branchArgs initialArgs = {firstG2F, firstVertex.x, firstVertex.y, _BranchLength, 90.0, 1.0};

				argStack.top = -1;
				push(initialArgs);

				// This while loop test was always false because I was passing the stacks in by value
				while (!(argStack.top == -1)) {

					branchArgs currentArgs = pop();
		
					float deltaX = cos (currentArgs.angle*0.0174533) * currentArgs.len;
					float deltaY = sin (currentArgs.angle*0.0174533) * currentArgs.len;

					float nextX = currentArgs.lastX + deltaX;
					float nextY = currentArgs.lastY + deltaY;

					float4 endPoint = float4(nextX, nextY, z, w);
					geometryOutput nextVertex;
					nextVertex.vertex = endPoint;
					nextVertex.uv = firstUV;

					float4 parallelPoint = float4(nextX+.2, nextY, z, w);
					geometryOutput paraVert;
					paraVert.vertex = parallelPoint;
					paraVert.uv = firstUV;

					geometryOutput o;

					// Append point on top of last point -- this is the base of the branch
					o.vertex = currentArgs.lastVertex.vertex;
					o.uv = currentArgs.lastVertex.uv;
					triStream.Append(o);

					// Append two points at the calculated end of the new branch
					o.vertex = nextVertex.vertex;
					o.uv = nextVertex.uv;
					triStream.Append(o);

					o.vertex = paraVert.vertex;
					o.uv = paraVert.uv;
					triStream.Append(o);

					triStream.RestartStrip();

					// Have to hard code this number so the compiler knows when this loop will terminate
					if (currentArgs.depth < 6.0) {
						struct branchArgs baRight = {nextVertex, nextX, nextY, currentArgs.len/2.0, currentArgs.angle+_DeltaAngle, currentArgs.depth+1.0};
						struct branchArgs baLeft = {nextVertex, nextX, nextY, currentArgs.len/2.0, currentArgs.angle-_DeltaAngle, currentArgs.depth+1.0};
						push(baRight);
						push(baLeft);
					}
				}
			}

			// Pixel shader function - called fragment shader
			fixed4 frag (geometryOutput i) : SV_Target
			{
				// Get color of pixel on screen by sampling the texture and uv data for model
				fixed4 col = tex2D(_Texture, i.uv);
                return col;
			}
			ENDCG
		}
	}
}
