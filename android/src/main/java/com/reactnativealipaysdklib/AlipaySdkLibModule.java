package com.reactnativealipaysdklib;

import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;

import com.alipay.sdk.app.PayTask;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import java.util.Map;

public class AlipaySdkLibModule extends ReactContextBaseJavaModule {

  private ReactApplicationContext mReactContext;
  private static final int SDK_PAY_FLAG = 1;

  public AlipaySdkLibModule(ReactApplicationContext context) {
    super(context);
    mReactContext = context;
  }

  @Override
  public String getName() {
    return "AlipaySdkLibModule";
  }

  @ReactMethod
  public void pay(final String orderInfo) {
    final Runnable payRunnable = new Runnable() {

      @Override
      public void run() {
        PayTask alipay = new PayTask(getCurrentActivity());
        Map<String, String> result = alipay.payV2(orderInfo, true);

        Message msg = new Message();
        msg.what = SDK_PAY_FLAG;
        msg.obj = result;
        mHandler.sendMessage(msg);
      }
    };

    // 必须异步调用
    Thread payThread = new Thread(payRunnable);
    payThread.start();
  }

  private Handler mHandler = new Handler(getReactApplicationContext().getMainLooper()) {
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case SDK_PAY_FLAG: {
          PayResult payResult = new PayResult((Map<String, String>) msg.obj);
          WritableMap resultMap = Arguments.createMap();
          /**
           * 对于支付结果，请商户依赖服务端的异步通知结果。同步通知结果，仅作为支付结束的通知。
           */
          String resultInfo = payResult.getResult();// 同步返回需要验证的信息
          String resultStatus = payResult.getResultStatus();
          String memo = payResult.getMemo();
          resultMap.putString("code", resultStatus);
          resultMap.putString("memo", memo);
          resultMap.putString("result",resultInfo);
          // 判断resultStatus 为9000则代表支付成功,该笔订单是否真实支付成功，需要依赖服务端的异步通知。
          if (TextUtils.equals(resultStatus, "9000")) {
            emit("onPaySuccessResponse",resultMap);
          } else {
            emit("onPayFailResponse",resultMap);
          }
          break;
        }
        default:
          break;
      }
    }
  };


  private void emit(String name, WritableMap params) {
    this.getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(name,params);
  }



}
