using System;
using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using Random = UnityEngine.Random;
using Vector2 = UnityEngine.Vector2;
using Vector3 = UnityEngine.Vector3;

public class utilies : MonoBehaviour
{
    /// <summary>
    /// returns a Vector2 containing max x and max y in WorldPoint
    /// </summary>
    /// <returns></returns>
    public static Vector2 GetCameraBounds(Camera camera)
    {
        var orthographicSize = camera.orthographicSize;
        return new Vector2(
            orthographicSize * Screen.width / Screen.height,
            orthographicSize * Screen.height / Screen.width
        );
    }

    public static Vector2 RandomPointInCollider(Collider2D collider,Camera camera)
    {
        Vector2 point;
        var count = 0;
        do
        {
            if (++count > 10000)
                throw new Exception("cannot find the point inside the collider within 10_000 tries!");
            var randomViewPortPoint = new Vector3(Random.Range(0f, 1f), Random.Range(0f, 1f), 0f);
            point = camera.ViewportToWorldPoint(randomViewPortPoint);
        } while (!collider.OverlapPoint(point));

        return point;
    }

    public static Color HexToColor(string hex)
    {
        return ColorUtility.TryParseHtmlString(hex, out var newCol) ? newCol : Color.black;
    }

    public static string NumToStr(BigInteger num)
    {
        var root = new[] {"", "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "d", "U", "D"};
        var pattern = num.ToString("N0");
        var commas = pattern.Split('.');
        if (commas.Length <= 2)
            return num.ToString("N0");
        return commas[0] + "," + commas[1] + " " + root[commas.Length - 1];
    }

    public static string DoubleToStr(double num)
    {
        if (double.IsNaN(num))
            return "0";
        return num < 1000 ? num.ToString("F1") : NumToStr(new BigInteger(num));
    }
}