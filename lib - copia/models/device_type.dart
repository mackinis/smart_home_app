import 'device_action.dart';

enum DeviceType {
  accessControl,
  lightSwitch,
  custom;

  List<DeviceAction> get actions {
    switch (this) {
      case DeviceType.accessControl:
        return DeviceTypeTemplates.accessControlActions;
      case DeviceType.lightSwitch:
        return DeviceTypeTemplates.lightActions;
      case DeviceType.custom:
        return DeviceTypeTemplates.customActions;
    }
  }
}

class DeviceTypeTemplates {
  static final accessControlActions = [
    DeviceAction(
      id: 'open_door',
      label: 'Abrir puerta',
      params: [],
      commandTemplate: 'open',
    ),
    DeviceAction(
      id: 'suspend_card',
      label: 'Suspender tarjeta',
      params: [
        ActionParam(key: 'id', label: 'ID (2 dígitos)', regex: r'^\d{2}$'),
      ],
      commandTemplate: 'suspendcard:{id}',
    ),
    DeviceAction(
      id: 'activate_card',
      label: 'Activar tarjeta',
      params: [
        ActionParam(key: 'id', label: 'ID (2 dígitos)', regex: r'^\d{2}$'),
      ],
      commandTemplate: 'activatecard:{id}',
    ),
    DeviceAction(
      id: 'delete_card',
      label: 'Borrar tarjeta',
      params: [
        ActionParam(key: 'id', label: 'ID (2 dígitos)', regex: r'^\d{2}$'),
      ],
      commandTemplate: 'deletecard:{id}',
    ),
    DeviceAction(
      id: 'add_code',
      label: 'Agregar código',
      params: [
        ActionParam(key: 'code', label: 'Código (4-8 dígitos)', regex: r'^\d{4,8}$'),
      ],
      commandTemplate: 'addcode:{code}',
    ),
    DeviceAction(
      id: 'delete_code',
      label: 'Borrar código',
      params: [
        ActionParam(key: 'code', label: 'Código (4-8 dígitos)', regex: r'^\d{4,8}$'),
      ],
      commandTemplate: 'delcode:{code}',
    ),
    DeviceAction(
      id: 'change_master',
      label: 'Cambiar código maestro',
      params: [
        ActionParam(key: 'master', label: 'Nuevo maestro (4-8 dígitos)', regex: r'^\d{4,8}$', obscure: true),
      ],
      commandTemplate: 'master:{master}',
    ),
    DeviceAction(
      id: 'factory_reset',
      label: 'Reset de fábrica',
      params: [
        ActionParam(key: 'master', label: 'Código maestro actual', obscure: true),
      ],
      commandTemplate: 'factoryreset:{master}',
    ),
  ];

  static final lightActions = [
    DeviceAction(
      id: 'light_on',
      label: 'Encender luz',
      params: [],
      commandTemplate: 'on',
    ),
    DeviceAction(
      id: 'light_off',
      label: 'Apagar luz',
      params: [],
      commandTemplate: 'off',
    ),
  ];

  static final customActions = [
    DeviceAction(
      id: 'custom',
      label: 'Enviar comando personalizado',
      params: [
        ActionParam(key: 'cmd', label: 'Comando'),
      ],
      commandTemplate: '{cmd}',
    ),
  ];
}