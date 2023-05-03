using System;
using System.Diagnostics;
using System.Numerics;
using TMPro;
using UnityEngine;
using Debug = UnityEngine.Debug;
using Quaternion = UnityEngine.Quaternion;
using Vector2 = UnityEngine.Vector2;

namespace utiles
{
    public class Effect : MonoBehaviour
    {
        public static void ClickEffect(Vector2 position, Color color)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();
            var circle = new Circle(0.2f, position);
            float alpha = 0;
            for (var i = 0; i < 8; ++i)
            {
                var circleGo = Instantiate(Resources.Load("Prefabs/circle") as GameObject);
                circleGo.GetComponent<SpriteRenderer>().color = color;
                circleGo.transform.SetPositionAndRotation(circle.GetPointFromAngle(alpha),
                    Quaternion.Euler(0, 0, Mathf.Rad2Deg * alpha));
                circleGo.transform.localScale = new Vector2(0.12f, 0.12f);

                var direction = circle.GetPointFromAngle(alpha) - circle.Center;
                circleGo.GetComponent<Rigidbody2D>().velocity = direction * CircleScript.Velocity;
                circleGo.GetComponent<Rigidbody2D>().AddForce(-direction * 1600f);

                alpha += 2 * Mathf.PI / 8;
            }

            stopwatch.Stop();
            // Debug.Log("CircleEffect took--> " + stopwatch.ElapsedTicks);
        }

        public static void SpawnFloatingText(Vector2 position, BigInteger value, float duration,
            string color = "#8EFF7C")
        {
            var floating = Instantiate(
                Resources.Load<GameObject>("Prefabs/Floating"),
                position, Quaternion.identity,
                GameObject.Find("Canvas").transform);
            floating.GetComponent<FloatingText>().duration = duration;
            foreach (var text in floating.transform.GetComponentsInChildren<TextMeshProUGUI>())
            {
                text.color = utilies.HexToColor(color);
                if (!text.text.Equals("+"))
                    text.text = utilies.NumToStr(value);
            }
        }
    }
}