struct PS_INPUT
{
  float4 pos : SV_POSITION;
  float3 color : COLOR0;
};

float4 main(PS_INPUT input) : SV_Target
{
  return float4(input.color, 1.0);
}
