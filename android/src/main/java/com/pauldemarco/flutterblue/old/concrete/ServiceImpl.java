package com.pauldemarco.flutterblue.concrete;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;

import com.pauldemarco.flutterblue.ChannelPaths;
import com.pauldemarco.flutterblue.Characteristic;
import com.pauldemarco.flutterblue.Device;
import com.pauldemarco.flutterblue.Guid;
import com.pauldemarco.flutterblue.Service;
import com.polidea.rxandroidble.RxBleConnection;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import rx.Observable;
import rx.Single;

/**
 * Created by paul on 6/26/17.
 */

public class ServiceImpl extends Service implements MethodCallHandler {

    private final Registrar registrar;
    private final MethodChannel methodChannel;
    private final Observable<RxBleConnection> connectionObservable;

    public ServiceImpl(Registrar registrar, Guid guid, Device device, boolean isPrimary, Observable<RxBleConnection> connectionObservable) {
        super(guid, isPrimary, device);
        this.registrar = registrar;
        this.methodChannel = new MethodChannel(registrar.messenger(), ChannelPaths.getServiceMethodsPath(device.getGuid().toString(), guid.toString()));
        this.methodChannel.setMethodCallHandler(this);
        this.connectionObservable = connectionObservable;
    }

    public ServiceImpl(Registrar registrar, BluetoothGattService service, Device device, Observable<RxBleConnection> connectionObservable) {
        this(
                registrar,
                new Guid(service.getUuid()),
                device,
                service.getType()==BluetoothGattService.SERVICE_TYPE_PRIMARY,
                connectionObservable
        );
        for(BluetoothGattService s : service.getIncludedServices()) {
            ServiceImpl innerService = new ServiceImpl(registrar, s, device, connectionObservable);
            includedServices.add(innerService);
        }
        for(BluetoothGattCharacteristic nativeChar : service.getCharacteristics()) {
            CharacteristicImpl c = CharacteristicImpl.fromGattCharacteristic(registrar, nativeChar, this, device, connectionObservable);
            characteristics.add(c);
        }
    }

    @Override
    public Single<List<Service>> getIncludedServices() {
        return null;
    }

    @Override
    public Single<List<Characteristic>> getCharacteristics() {
        return null;
    }

    @Override
    public Single<Characteristic> getCharacteristic() {
        return null;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> m = new HashMap<>();
        m.put("id", this.guid.toString());
        m.put("isPrimary", this.isPrimary);

        // Serialize the list of included services
        List<Map<String, Object>> outServices = new ArrayList<>(includedServices.size());
        for(Service s : includedServices) {
            outServices.add(s.toMap());
        }
        m.put("includedServices", outServices);

        // Serialize the list of characteristics
        List<Map<String, Object>> outCharacteristics = new ArrayList<>(characteristics.size());
        for(Characteristic c : characteristics) {
            outCharacteristics.add(c.toMap());
        }
        m.put("characteristics", outCharacteristics);
        return m;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getIncludedServices")) {
            List<Map<String, Object>> servicesMapList = new ArrayList<>(includedServices.size());
            for(Service s : includedServices) {
                servicesMapList.add(s.toMap());
            }
            result.success(servicesMapList);

        } else if (call.method.equals("getCharacteristics")) {

        } else if (call.method.equals("getCharacteristic")) {
            String id = (String)call.arguments;
            Guid guid = new Guid(id);
            for(Characteristic c : characteristics) {
                if(guid.equals(c.getGuid())) {
                    result.success(c.toMap());
                    return;
                }
            }
            result.error("GET_CHARACTERISTIC_ERROR", "Characteristic not found with id " + guid.toString(), null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public boolean equals(Object o) {
        if(this == o) return true;
        if(o == null) return false;
        if(getClass() != o.getClass()) return false;
        ServiceImpl other = (ServiceImpl) o;
        return guid.equals(other.getGuid());
    }

    @Override
    public int hashCode() {
        return this.guid.hashCode();
    }
}
