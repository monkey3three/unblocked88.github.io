using UnityEngine;

public class Circle
{
    private float Radius { get; }
    public Vector2 Center { get; }

    public Circle(float radius, Vector2 center)
    {
        this.Radius = radius;
        this.Center = center;
    }
    public Circle(Vector2 center)
    {
        Radius = 0f;
        this.Center = center;
    }


    public Vector2 GetPointFromAngle(float angleRadiant)
    {
        var vec= new Vector2((Mathf.Cos(angleRadiant) * Radius + Center.x),
                           (Mathf.Sin(angleRadiant) * Radius + Center.y));
        return vec;
    }

    public float GetAngleByPoint(Vector2 point)
    {
        float radius = Mathf.Sqrt(Mathf.Pow(Center.x - point.x, 2) + Mathf.Pow(Center.y - point.y, 2));
        if (point.y > Center.y)
            return -(Mathf.Acos((+point.x - Center.x) / radius) / Mathf.PI * 180f);
        return Mathf.Acos((+point.x - Center.x) / radius) / Mathf.PI * 180f;
    }

    public float GetDistanceFromCenter(Vector2 point)
    {
        return Mathf.Sqrt(Mathf.Pow(Center.x - point.x, 2) + Mathf.Pow(Center.y - point.y, 2));
    }
}
