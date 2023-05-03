using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using TMPro;
using UnityEngine;

public class FpsCounter : MonoBehaviour
{
    public TextMeshProUGUI text;

    private float _time,_count;

    private void Update()
    {
        _time += Time.deltaTime;
        ++_count;
        if (_time < 0.5f)
            return;
        text.text = (_count / _time).ToString(CultureInfo.InvariantCulture);
        _time -=0.5f;
        _count = 0;
    }
}